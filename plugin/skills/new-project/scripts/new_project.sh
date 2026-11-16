#!/usr/bin/env bash
# new-project: create ~/code/<name> on the agent-kit layout (kit PROJECT.md §1) with a copy of
# the latest kit release, commit it, and optionally publish it as a private GitHub repo.
#
# new_project.sh <name> --title "<Title>" --purpose "<2-3 English sentences>" \
#                --objective "<одна фраза по-русски>" [--modules research-experiments,clusters]
#                [--github] [--dir <parent dir, default ~/code>]
set -euo pipefail

die() { echo "new-project: $*" >&2; exit 1; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

HERE="$(cd "$(dirname "$0")" && pwd)"
TPL="$HERE/../templates"
HERE_KIT="$(cd "$HERE/../../../.." && pwd)"

name="${1:-}"; [ -n "$name" ] && shift || die "usage: new_project.sh <name> --title … --purpose … --objective … [--modules …] [--github]"
title="" purpose="" objective="" modules="" github=0 parent="$HOME/code"
while [ $# -gt 0 ]; do
  case "$1" in
    --title) title="$2"; shift 2;;
    --purpose) purpose="$2"; shift 2;;
    --objective) objective="$2"; shift 2;;
    --modules) modules="$2"; shift 2;;
    --github) github=1; shift;;
    --dir) parent="$2"; shift 2;;
    *) die "unknown argument: $1";;
  esac
done

[[ "$name" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || die "name must be lowercase letters, digits and dashes: $name"
[ -n "$title" ] && [ -n "$purpose" ] && [ -n "$objective" ] || die "--title, --purpose and --objective are required"
for m in ${modules//,/ }; do
  case "$m" in research-experiments|clusters) ;; *) die "unknown module: $m (known: research-experiments, clusters)";; esac
done
dest="$parent/$name"
[ ! -e "$dest" ] || die "$dest already exists"
command -v git >/dev/null || die "git is missing"
command -v python3 >/dev/null || die "python3 is missing"
if [ "$github" = 1 ]; then
  command -v gh >/dev/null || die "gh is missing (or drop --github)"
  OWNER="${NEW_PROJECT_OWNER:-$(gh api user -q .login 2>/dev/null || true)}"
  [ -n "$OWNER" ] || die "gh is not signed in (gh auth login) or set NEW_PROJECT_OWNER"
  if [ "$(gh repo view "$OWNER/$name" --json name -q .name 2>/dev/null || true)" = "$name" ]; then
    die "github.com/$OWNER/$name already exists"
  fi
fi

# --- the kit release: the newest releases/vX.Y next to this plugin, or in $AGENT_KIT_DIR
kitsrc="${AGENT_KIT_DIR:-$HERE_KIT}"
[ -d "$kitsrc/releases" ] || die "no releases/ in $kitsrc (set AGENT_KIT_DIR to your agent-kit checkout)"
kit="$(cd "$kitsrc/releases" && ls -d v*/ | tr -d / | sort -V | tail -1)"
[ -n "$kit" ] || die "no release in $kitsrc/releases"
rel="$kitsrc/releases/$kit"
(cd "$rel" && sha -c MANIFEST.sha256 >/dev/null) || die "release $kit does not match its own manifest"

mkdir -p "$dest/agent-kit/$kit" "$dest/docs"
cp "$rel/MANIFEST.sha256" "$dest/agent-kit/$kit/"
while read -r _ f; do
  mkdir -p "$dest/agent-kit/$kit/$(dirname "$f")"
  cp "$rel/$f" "$dest/agent-kit/$kit/$f"
done < "$rel/MANIFEST.sha256"
(cd "$dest/agent-kit/$kit" && sha -c MANIFEST.sha256 >/dev/null) || die "the copy does not match the manifest"
hash="$(sha "$dest/agent-kit/$kit/MANIFEST.sha256" | cut -d' ' -f1)"

# --- render the templates
NAME="$name" TITLE="$title" PURPOSE="$purpose" OBJECTIVE="$objective" MODULES="$modules" \
KIT="$kit" HASH="$hash" CANON="$( [ "$github" = 1 ] && echo "github.com/$OWNER/$name" || echo "a local repository (no remote yet)")" TPL="$TPL" DEST="$dest" python3 - <<'PY'
import os, datetime
try:
    now = datetime.datetime.now().astimezone()
except Exception:
    now = datetime.datetime.now()
e = os.environ
kit = e["KIT"]
mods = [m for m in e["MODULES"].split(",") if m]
months = ["января","февраля","марта","апреля","мая","июня","июля","августа",
          "сентября","октября","ноября","декабря"]
rows, cons = "", ""
if "clusters" in mods:
    rows += (f"| any operation on a cluster | kit [`modules/clusters.md`](agent-kit/{kit}/modules/clusters.md); "
             "`docs/OPERATIONS.md` once it exists |\n")
    cons += ("- On a cluster, never write project files under `/home`; a new Slurm allocation only at "
             "the owner's explicit request (kit `modules/clusters.md`).\n")
if "research-experiments" in mods:
    rows += (f"| choosing, launching, monitoring or interpreting an experiment | kit "
             f"[`modules/research-experiments.md`](agent-kit/{kit}/modules/research-experiments.md); "
             "`docs/RULES.md` once it exists |\n")
    cons += ("- Launch only experiments the owner approved, by the kit `research-experiments` module; "
             "without `docs/RULES.md` no research actions (code work is not blocked).\n")
v = {
    "NAME": e["NAME"], "TITLE": e["TITLE"], "PURPOSE": e["PURPOSE"].strip(),
    "PURPOSE_RU": e["OBJECTIVE"].strip(), "KIT": kit, "VERSION": kit.lstrip("v"),
    "HASH": e["HASH"], "CANON": e["CANON"], "MODULES": ", ".join(mods) if mods else "none",
    "MODULE_ROWS": rows, "MODULE_CONSTRAINTS": cons,
    "DATE": now.strftime("%Y-%m-%d"), "TIME": now.strftime("%H:%M"),
    "DATETIME": now.strftime("%Y-%m-%d %H:%M %Z"),
    "DATE_RU": f"{now.day} {months[now.month-1]}",
}
out = {"AGENTS.md": "AGENTS.md", "STATUS.md": "docs/STATUS.md", "DECISIONS.md": "docs/DECISIONS.md",
       "LESSONS.md": "docs/LESSONS.md", "HISTORY.md": "docs/HISTORY.md", "gitignore": ".gitignore"}
for src, dst in out.items():
    text = open(os.path.join(e["TPL"], src), encoding="utf-8").read()
    for k, val in v.items():
        text = text.replace("{{" + k + "}}", val)
    assert "{{" not in text, f"unfilled placeholder in {src}"
    open(os.path.join(e["DEST"], dst), "w", encoding="utf-8").write(text)
open(os.path.join(e["DEST"], "CLAUDE.md"), "w", encoding="utf-8").write("@AGENTS.md\n")
PY

# --- git and GitHub
cd "$dest"
git init -q -b main
git add -A
git commit -q -m "Create $name on the agent-kit $kit layout" \
  -m "Agent entry, project summary, registers and a copy of agent-kit $kit; created with the new-project skill."
echo "created $dest  (kit $kit, modules: ${modules:-none})"

if [ "$github" = 1 ]; then
  gh repo create "$OWNER/$name" --private --source . --remote origin --push >/dev/null
  echo "published https://github.com/$OWNER/$name (private)"
fi

