#!/usr/bin/env bash
# new-notes: create the personal memory repository from templates/notes.
#
# new_notes.sh [--dir <parent dir, default ~/code>] [--name notes] [--github]
set -euo pipefail

die() { echo "new-notes: $*" >&2; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../../lib/kit_root.sh"

parent="$HOME/code" name="notes" github=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) parent="$2"; shift 2;;
    --name) name="$2"; shift 2;;
    --github) github=1; shift;;
    *) die "unknown argument: $1";;
  esac
done
[[ "$name" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || die "name must be lowercase letters, digits and dashes: $name"
dest="$parent/$name"
[ ! -e "$dest" ] || die "$dest already exists"
command -v git >/dev/null || die "git is missing"
kitsrc="$(kit_root)" || exit 1
tpl="$kitsrc/templates/notes"
[ -f "$tpl/AGENTS.md" ] || die "no templates/notes in $kitsrc"
if [ "$github" = 1 ]; then
  command -v gh >/dev/null || die "gh is missing (or drop --github)"
  owner="${NEW_PROJECT_OWNER:-$(gh api user -q .login 2>/dev/null || true)}"
  [ -n "$owner" ] || die "gh is not signed in (gh auth login) or set NEW_PROJECT_OWNER"
  [ "$(gh repo view "$owner/$name" --json name -q .name 2>/dev/null || true)" != "$name" ] || die "github.com/$owner/$name already exists"
fi

mkdir -p "$parent"
cp -R "$tpl" "$dest"
mv "$dest/gitignore" "$dest/.gitignore"
month="$(date +%Y-%m)"; now="$(date '+%Y-%m-%d %H:%M')"
printf '# Журнал %s\n\n- %s — Репозиторий памяти создан из шаблона agent-kit (навык new-notes).\n' "$month" "$now" > "$dest/log/$month.md"
(cd "$dest" && python3 scripts/validate_notes.py >/dev/null) || die "the new repository does not pass its own validator"

cd "$dest"
git init -q -b main
git add -A
git commit -q -m "Create the notes repository from the agent-kit template"
echo "created $dest"
if [ "$github" = 1 ]; then
  gh repo create "$owner/$name" --private --source . --remote origin --push >/dev/null
  echo "published https://github.com/$owner/$name (private)"
fi
