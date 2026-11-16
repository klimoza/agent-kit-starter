---
name: new-project
description: Create a new project on the agent-kit layout — a ~/code/<name> repository with the agent entry, project summary, registers and a copy of the latest kit release, optionally published as a private GitHub repo.
disable-model-invocation: true
argument-hint: "<name> [what the project is for]"
---

# New project

The owner asked for a new project: `$ARGUMENTS`.

## 1. Settle the inputs (ask only for what is missing)

- **name** — the repo and folder name: lowercase, digits, dashes (`garden-planner`).
- **title** — how the project is called in documents (`Garden planner`).
- **purpose** — two or three English sentences for the agent entry: what the project is and what
  the owner decides in it. Write them from the owner's words; do not invent scope.
- **objective** — one plain phrase in the owner's language for the project summary (`objective`
  field, kit `STATUS.md` §2): what the project is for, as a colleague would say it aloud.
- **modules** — `clusters` if it will run anything on a compute cluster, `research-experiments`
  if it runs research experiments; otherwise none.
- **github** — whether to publish it as a private GitHub repository (`--github`, needs `gh` signed in).

Show the owner the inputs in one short message and go on unless they object.

## 2. Run

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/new_project.sh" <name> \
  --title "<title>" --purpose "<purpose>" --objective "<objective>" \
  [--modules clusters,research-experiments] [--github] [--dir <parent, default ~/code>]
```

The script refuses if the folder (or the GitHub repo) already exists, takes the newest release from
`releases/` of this kit (or `$AGENT_KIT_DIR`), copies exactly the files of its `MANIFEST.sha256`,
checks the copy, fills the templates and commits on `main`.

If the script stops, report its message as it is; do not finish its steps by hand.

## 3. Tell the owner what is left

Open the folder in Claude Code: the agent reads `AGENTS.md` first. Describe the first
task; the agent records it in `docs/STATUS.md`.
