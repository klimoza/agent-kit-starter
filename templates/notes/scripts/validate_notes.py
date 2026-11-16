#!/usr/bin/env python3
"""Check the Notes format before every commit: task fields and the map.

Run from the repository root: python3 scripts/validate_notes.py
Exit code 0 when everything holds, 1 with one line per problem otherwise.
"""
import datetime
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = ('status', 'due', 'next_action', 'ask', 'waiting_for', 'review_on', 'source')
STATUSES = ('open', 'needs-input', 'waiting')
EMPTY = ('', '—', '-', '…', '...')


def parse_tasks(text):
    tasks = {}
    current = None
    for line in text.splitlines():
        head = re.match(r'^## (T-\d{3,}) — (.+)$', line)
        if head:
            current = {'title': head.group(2).strip()}
            if head.group(1) in tasks:
                current['duplicate'] = True
            tasks[head.group(1)] = current
            continue
        if line.startswith('## '):
            current = None
        field = re.match(r'^- ([a-z_]+): ?(.*)$', line)
        if current is not None and field:
            current[field.group(1)] = field.group(2).strip()
    return tasks


def check(root=ROOT):
    errors = []
    tasks_file = root / 'tasks.md'
    map_file = root / 'personal_context.md'
    for required in (tasks_file, map_file, root / 'AGENTS.md', root / 'systems.md'):
        if not required.is_file():
            errors.append(f'{required.name}: file is missing')
    if errors:
        return errors

    tasks = parse_tasks(tasks_file.read_text(encoding='utf-8'))
    for task_id, task in tasks.items():
        if task.get('duplicate'):
            errors.append(f'{task_id}: the ID is used twice in tasks.md')
        for name in REQUIRED:
            if name not in task:
                errors.append(f'{task_id}: field {name} is missing')
        if task.get('status') not in STATUSES and 'status' in task:
            errors.append(f'{task_id}: status must be one of {", ".join(STATUSES)}')
        if task.get('next_action', 'x') in EMPTY:
            errors.append(f'{task_id}: next_action is empty')
        if 'review_on' in task:
            try:
                datetime.date.fromisoformat(task['review_on'])
            except ValueError:
                errors.append(f'{task_id}: review_on must be a date YYYY-MM-DD')
        if task.get('status') == 'waiting' and task.get('waiting_for', '') in EMPTY:
            errors.append(f'{task_id}: status is waiting but waiting_for is empty')

    map_text = re.sub(r'<!--.*?-->', '', map_file.read_text(encoding='utf-8'), flags=re.S)
    in_map = set(re.findall(r'\bT-\d{3,}\b', map_text))
    for task_id in sorted(set(tasks) - in_map):
        errors.append(f'{task_id}: open task is not listed in personal_context.md')
    for task_id in sorted(in_map - set(tasks)):
        errors.append(f'{task_id}: listed in personal_context.md but not in tasks.md')

    for log in sorted((root / 'log').glob('*.md')):
        if log.name != 'README.md' and not re.fullmatch(r'\d{4}-\d{2}\.md', log.name):
            errors.append(f'log/{log.name}: journal files are named YYYY-MM.md')
    return errors


if __name__ == '__main__':
    problems = check()
    for problem in problems:
        print(problem)
    print('notes: ' + ('OK' if not problems else f'{len(problems)} problem(s)'))
    sys.exit(1 if problems else 0)
