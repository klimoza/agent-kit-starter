---
name: new-notes
description: Create the owner's personal memory repository (notes) from the agent-kit template — tasks, areas, journal, shared agent memory and handoff files — optionally published as a private GitHub repo.
disable-model-invocation: true
argument-hint: "[--github]"
---

# New notes repository

The owner asked for their memory repository: `$ARGUMENTS`.

1. Run:
   ```sh
   bash "${CLAUDE_SKILL_DIR}/scripts/new_notes.sh" [--dir <parent, default ~/code>] [--name notes] [--github]
   ```
   The script refuses if the folder (or the GitHub repo) already exists, copies
   `templates/notes` of the kit checkout, starts the journal, runs the validator and commits
   on `main`. `--github` publishes it as a **private** repository (needs `gh` signed in).
   If the script stops, report its message as it is; do not finish its steps by hand.
2. Ask the owner three things and record the answers in the new repository by its own
   `AGENTS.md` (journal line, canonical file, validator, commit): how to address them and in
   which language (`profile.md`); two or three current directions (`areas.md` and the map);
   one real task they have in mind (`tasks.md` with every field, and the map).
3. Tell the owner what is left: connect the repository to their coordinator project in
   claude.ai/code and paste the project instructions from the kit's
   `templates/claude-project-instructions.md` (the kit's `SETUP.md`, step 2).
