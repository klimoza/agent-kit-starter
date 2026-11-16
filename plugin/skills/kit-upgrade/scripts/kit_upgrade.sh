#!/usr/bin/env bash
# kit-upgrade: move a project's agent-kit copy to another release.
#
# kit_upgrade.sh --list [dir]                projects under ~/code (or dir) with a kit copy, and their versions
# kit_upgrade.sh [--to vX.Y] <repo-dir>…     copy the release (default: newest sealed), repoint AGENTS.md,
#                                            show what changed; commits nothing, removes nothing
set -euo pipefail

die() { echo "kit-upgrade: $*" >&2; exit 1; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
pluginlib="$(cd "$(dirname "$0")/../../../lib" && pwd)"
. "$pluginlib/kit_root.sh"

kitsrc="$(kit_root)" || exit 1
newest="$(cd "$kitsrc/releases" && ls v*/MANIFEST.sha256 2>/dev/null | cut -d/ -f1 | sort -V | tail -1)"
[ -n "$newest" ] || die "no sealed release in $kitsrc/releases"

if [ "${1:-}" = "--list" ]; then
  root="${2:-$HOME/code}"
  find "$root" -maxdepth 5 -path '*/agent-kit/v*/MANIFEST.sha256' -not -path "$kitsrc/*" 2>/dev/null |
    while read -r m; do
      repo="${m%/agent-kit/*}"; v="$(basename "$(dirname "$m")")"
      named="$(python3 "$pluginlib/kit_entry.py" version "$repo/AGENTS.md" 2>/dev/null)" || named="invalid or missing pin"
      flag=""; [ "$v" = "$newest" ] || flag="  (newest: $newest)"
      [ "$named" = "$v" ] || flag="$flag  (AGENTS.md names ${named:-nothing})"
      echo "$repo  $v$flag"
    done
  exit 0
fi

to="$newest"
if [ "${1:-}" = "--to" ]; then to="$2"; shift 2; fi
[ $# -gt 0 ] || die "usage: kit_upgrade.sh --list [dir] | [--to vX.Y] <repo-dir>…"
rel="$kitsrc/releases/$to"
[ -f "$rel/MANIFEST.sha256" ] || die "no sealed release $to"
(cd "$rel" && sha -c MANIFEST.sha256 >/dev/null) || die "release $to does not match its own manifest"

for repo in "$@"; do
  repo="$(cd "$repo" && pwd)"
  entry="$repo/AGENTS.md"
  echo "== $repo"
  [ -f "$entry" ] || { echo "   no AGENTS.md, skipped"; continue; }
  from="$(python3 "$pluginlib/kit_entry.py" version "$entry")" || die "$from"
  copy="$(python3 "$pluginlib/kit_entry.py" copy "$entry")" || die "$copy"
  case "$copy" in releases/*) die "this is the kit repository itself: releases are immutable, make a new one with scripts/release.sh" ;; esac
  [ "$from" != "$to" ] || { echo "   already on $to"; continue; }
  if [ -n "$(git -C "$repo" status --porcelain -- AGENTS.md "agent-kit/$to" 2>/dev/null)" ]; then
    echo "   AGENTS.md or agent-kit/$to has uncommitted changes, skipped"; continue
  fi

  dst="$repo/agent-kit/$to"
  rm -rf "$dst"; mkdir -p "$dst"
  cp "$rel/MANIFEST.sha256" "$dst/"
  while read -r _ f; do mkdir -p "$dst/$(dirname "$f")"; cp "$rel/$f" "$dst/$f"; done < "$rel/MANIFEST.sha256"
  (cd "$dst" && sha -c MANIFEST.sha256 >/dev/null) || die "copy in $dst does not match the manifest"
  hash="$(sha "$dst/MANIFEST.sha256" | cut -d' ' -f1)"

  TO="$to" HASH="$hash" ENTRY="$entry" PLUGIN_LIB="$pluginlib" python3 - <<'PY'
import os, sys
e = os.environ
sys.path.insert(0, e["PLUGIN_LIB"])
from kit_entry import rewrite_pin
p = e["ENTRY"]
t = rewrite_pin(open(p, encoding="utf-8").read(), e["TO"], e["HASH"])
open(p, "w", encoding="utf-8").write(t)
PY

  echo "   copied $to (MANIFEST.sha256 $hash), AGENTS.md now points at it; agent-kit/$from is left in place"
  git -C "$repo" --no-pager diff --stat -- AGENTS.md
  left="$(cd "$repo" && grep -rIlE --exclude-dir=.git --exclude-dir="agent-kit" "agent-kit/${from//./\\.}([^0-9.]|$)" . 2>/dev/null || true)"
  if [ -n "$left" ]; then echo "   other files still citing agent-kit/$from:"; echo "$left" | sed 's/^/     /'; fi
  echo "   what the release changed: $kitsrc/CHANGELOG.md, entry $to"
done
