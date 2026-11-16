---
name: kit-upgrade
description: Move projects to a newer agent-kit release — list which projects carry which kit copy, copy the new release into a project, repoint its AGENTS.md, and apply what the release changed; commits only on the owner's yes.
disable-model-invocation: true
argument-hint: "[--list | project…] [--to vX.Y]"
---

# Kit upgrade

The owner asked: `$ARGUMENTS`.

1. **See where things stand** (always, first):
   `bash "${CLAUDE_SKILL_DIR}/scripts/kit_upgrade.sh" --list`
   prints every project under `~/code` with its kit copy, the newest sealed release, and any
   project whose AGENTS.md names a different copy than it carries. If the owner named no
   project, show this list and ask which to move.
2. **Read what the release changes** before touching a project: the release's entry in the kit
   repository's `CHANGELOG.md`. Say in two or three sentences what it will mean for each
   project (new obligations, renamed files, removed rules).
3. **Copy and repoint**, per project:
   `bash "${CLAUDE_SKILL_DIR}/scripts/kit_upgrade.sh" [--to vX.Y] ~/code/<project>`
   The script copies exactly the files of the release's `MANIFEST.sha256` into
   `agent-kit/vX.Y/`, checks the copy, and rewrites the copy path, version and hash in AGENTS.md.
   It skips a project whose AGENTS.md has uncommitted changes, commits nothing and leaves the old
   copy in place. It lists other files that still cite the old copy.
4. **Apply the release's changes** to the project's own files, as the CHANGELOG entry requires;
   update the `deviations` line where the project now differs. Keep others' uncommitted work.
   Then repoint the remaining citations of the old copy (historical records such as HISTORY
   entries keep the version they cite).
5. **Show the owner** the diff summary per project and ask. Only on their yes: `git rm -r -q
   agent-kit/<old>`, one commit per project (`Move to agent-kit vX.Y`), a HISTORY entry, push
   with `git pull --rebase` first, no force.
