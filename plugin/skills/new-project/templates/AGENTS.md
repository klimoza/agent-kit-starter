# {{TITLE}} — agent entry

{{PURPOSE}}

## Read

Always: kit CORE ([`agent-kit/{{KIT}}/CORE.md`](agent-kit/{{KIT}}/CORE.md)), this file, and `## Project summary` in
[`docs/STATUS.md`](docs/STATUS.md). Then by task (kit [`PROJECT.md`](agent-kit/{{KIT}}/PROJECT.md) §0):

| Task | Read |
|---|---|
| planning, interpreting or changing the project | the open entries of [`docs/LESSONS.md`](docs/LESSONS.md) on the topic; `docs/DIRECTION.md` once it exists |
| asking the owner, an action under a constraint | [`docs/DECISIONS.md`](docs/DECISIONS.md) |
| writing the status | kit [`STATUS.md`](agent-kit/{{KIT}}/STATUS.md) §2 |
| past events | [`docs/HISTORY.md`](docs/HISTORY.md), git log |
{{MODULE_ROWS}}| creating or editing any of these files | kit [`PROJECT.md`](agent-kit/{{KIT}}/PROJECT.md), the relevant section |

## Active constraints

- Only the owner grants or refuses acceptance, publication and deploy, in their own words; never infer
  them from silence, elapsed time or passing checks.
- No secrets, tokens or personal data in the repository.
{{MODULE_CONSTRAINTS}}
## Agent kit
- version: {{VERSION}} — [`agent-kit/{{KIT}}/`](agent-kit/{{KIT}}/), a copy of the portable set of release {{KIT}} (sha256 MANIFEST.sha256: {{HASH}})
- layout: PROJECT.md; canon — `main` of {{CANON}}
- modules: {{MODULES}}
- extensions: none
- deviations: none

Check the copy before use (macOS: `shasum -a 256`):
`sha256sum agent-kit/{{KIT}}/MANIFEST.sha256` must print the hash above, and
`(cd agent-kit/{{KIT}} && sha256sum -c MANIFEST.sha256)` must report every file OK. If not, say so;
never substitute a draft or another copy.
