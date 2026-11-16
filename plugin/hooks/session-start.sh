#!/usr/bin/env bash
# agent-kit, SessionStart: check the project's kit copy against the hash in its AGENTS.md
# and remind the agent of the standing rules. Prints plain text, which Claude Code adds to
# the session's context. Prints nothing outside kit projects (no "## Agent kit" in AGENTS.md).
# Never fails the session: every problem becomes a line of text.

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
entry="$dir/AGENTS.md"
[ -f "$entry" ] || exit 0
grep -q '^## Agent kit' "$entry" || exit 0

echo "agent-kit (session start):"
if command -v python3 >/dev/null 2>&1; then
  python3 "$(cd "$(dirname "$0")/.." && pwd)/lib/kit_entry.py" check "$dir"
else
  echo "- agent-kit: verification not run: python3 is unavailable. Say so to the owner."
fi

cat <<'TXT'
- Standing rules (kit CORE; the project's AGENTS.md is authoritative where it says more): acceptance, publication and deploy come only from the owner's own words, never from silence or passing checks. New compute allocations only at the owner's request. Messages and emails in the owner's name stay drafts until they say to send. No secrets or tokens in repositories. Uncommitted work that predates the task is preserved.
TXT
exit 0
