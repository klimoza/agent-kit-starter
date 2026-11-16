"""Read the pinned kit block; shared by SessionStart and kit-upgrade."""
from dataclasses import dataclass
import hashlib
from pathlib import Path
import re
import sys


@dataclass(frozen=True)
class Pin:
    version: str
    copy: str
    manifest_hash: str
    hash_span: tuple[int, int]


def parse_pin(text: str) -> Pin:
    block = re.search(r'^## Agent kit[^\n]*\n(.*?)(?=^#{1,2} |\Z)', text, re.M | re.S)
    if not block:
        raise ValueError('AGENTS.md has no Agent kit block')
    body = block.group(1)
    version = re.search(r'^- version:\s*(\d+\.\d+)\b', body, re.M)
    if not version:
        raise ValueError('AGENTS.md has no pinned kit version')
    copies = set(re.findall(r'(?<![\w/])((?:(?:docs/)?agent-kit|releases)/v\d+\.\d+/)', body))
    if len(copies) != 1:
        raise ValueError('AGENTS.md must name one kit copy agent-kit/vX.Y/ or releases/vX.Y/')
    copy = copies.pop()
    if not copy.endswith('/v' + version.group(1) + '/'):
        raise ValueError('AGENTS.md kit version and copy path disagree')
    hashes = list(re.finditer(
        r'MANIFEST\.sha256(?:\s+SHA-256)?\s*:\s*`?([0-9a-f]{64})\b', body))
    if not hashes:
        raise ValueError('AGENTS.md has no pinned manifest hash')
    if len(hashes) != 1:
        raise ValueError('AGENTS.md has ambiguous pinned manifest hashes')
    match = hashes[0]
    start, end = match.span(1)
    return Pin(version.group(1), copy, match.group(1),
               (block.start(1) + start, block.start(1) + end))


def rewrite_pin(text: str, target: str, digest: str) -> str:
    if not re.fullmatch(r'v\d+\.\d+', target) or not re.fullmatch(r'[0-9a-f]{64}', digest):
        raise ValueError('invalid target version or manifest hash')
    pin = parse_pin(text)
    start, end = pin.hash_span
    text = text[:start] + digest + text[end:]
    text = text.replace(pin.copy, 'agent-kit/' + target + '/')
    text = re.sub(r'(^- version:\s*)' + re.escape(pin.version) + r'\b',
                  lambda m: m.group(1) + target[1:], text, count=1, flags=re.M)
    text = re.sub(r'\brelease v' + re.escape(pin.version) + r'\b', 'release ' + target, text)
    parse_pin(text)  # Refuse to write a malformed result.
    return text


def project_entry(project: Path) -> Path:
    entry = project / 'AGENTS.md'
    text = entry.read_text(encoding='utf-8')
    local = project / 'AGENTS.local.md'
    if not re.search(r'^## Agent kit', text, re.M) and 'AGENTS.local.md' in text and local.is_file():
        return local
    return entry


def check_project(project: Path) -> str:
    entry = project_entry(project)
    pin = parse_pin(entry.read_text(encoding='utf-8'))
    copy = project / pin.copy
    manifest = copy / 'MANIFEST.sha256'
    if not manifest.is_file():
        raise ValueError(f'AGENTS.md names {pin.copy}, but the copy is missing here')
    raw = manifest.read_bytes()
    if hashlib.sha256(raw).hexdigest() != pin.manifest_hash:
        raise ValueError(f'{pin.copy}MANIFEST.sha256 does not match the hash in AGENTS.md')
    seen = set()
    for line in raw.decode('utf-8').splitlines():
        digest, name = line.split(maxsplit=1)
        relative = Path(name.lstrip('*'))
        path = copy / relative
        if (not re.fullmatch(r'[0-9a-f]{64}', digest) or relative.is_absolute()
                or '..' in relative.parts or relative in seen or path.is_symlink()
                or not path.resolve().is_relative_to(copy.resolve())):
            raise ValueError(f'{pin.copy}MANIFEST.sha256 contains an invalid file entry')
        seen.add(relative)
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError(f'a file in {pin.copy} differs from MANIFEST.sha256: {relative}')
    if not seen:
        raise ValueError(f'{pin.copy}MANIFEST.sha256 is empty')
    return (f'the copy {pin.copy} matches its manifest and the hash in AGENTS.md '
            '(checked by this hook); read its CORE.md as AGENTS.md says')


def main() -> int:
    try:
        action, raw = sys.argv[1:]
        if action == 'version':
            print('v' + parse_pin(Path(raw).read_text(encoding='utf-8')).version)
        elif action == 'copy':
            print(parse_pin(Path(raw).read_text(encoding='utf-8')).copy)
        elif action == 'check':
            print('- agent-kit: ' + check_project(Path(raw)) + '.')
        else:
            raise ValueError('expected check PROJECT or version ENTRY')
        return 0
    except (OSError, ValueError, UnicodeError) as exc:
        print('- agent-kit: ' + str(exc) + '. Say so to the owner; never substitute a draft or another copy.')
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
