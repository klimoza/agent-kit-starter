#!/usr/bin/env bash
# Make a new kit release. Releases are immutable once sealed.
#
#   scripts/release.sh new v1.1     copy the newest release to releases/v1.1 for editing
#   scripts/release.sh seal v1.1    write releases/v1.1/MANIFEST.sha256 and print its hash
#   scripts/release.sh check        verify every sealed release against its manifest
set -euo pipefail

die() { echo "release: $*" >&2; exit 1; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/releases" || die "no releases/ directory"

case "${1:-}" in
  new)
    to="${2:-}"; [[ "$to" =~ ^v[0-9]+\.[0-9]+$ ]] || die "usage: release.sh new vX.Y"
    [ ! -e "$to" ] || die "releases/$to already exists"
    from="$(ls -d v*/ | tr -d / | sort -V | tail -1)"
    cp -R "$from" "$to"; rm -f "$to/MANIFEST.sha256"
    old="${from#v}"; new="${to#v}"
    grep -rl -- "v$old\|$old — agent-kit" "$to" | while read -r f; do
      sed -i.bak -e "s/v${old//./\\.}/v$new/g" -e "s/${old//./\\.} — agent-kit/$new — agent-kit/g" "$f"; rm -f "$f.bak"
    done
    echo "releases/$to copied from $from (not sealed). Edit it, then: scripts/release.sh seal $to"
    ;;
  seal)
    to="${2:-}"; [ -d "$to" ] || die "usage: release.sh seal vX.Y"
    [ ! -f "$to/MANIFEST.sha256" ] || die "releases/$to is already sealed; releases are immutable, make a new one"
    (cd "$to" && find . -type f -name '*.md' | sed 's|^\./||' | LC_ALL=C sort | while read -r f; do sha "$f"; done > MANIFEST.sha256)
    hash="$(sha "$to/MANIFEST.sha256" | cut -d' ' -f1)"
    echo "sealed releases/$to"
    echo "SHA-256 of releases/$to/MANIFEST.sha256: $hash"
    echo "Add an entry for $to with this hash to CHANGELOG.md, commit, then move projects with /kit-upgrade."
    ;;
  check)
    for d in v*/; do
      d="${d%/}"
      if [ -f "$d/MANIFEST.sha256" ]; then
        (cd "$d" && sha -c MANIFEST.sha256 >/dev/null) && echo "$d OK" || die "$d does not match its manifest"
      else
        echo "$d not sealed"
      fi
    done
    ;;
  *) die "usage: release.sh new vX.Y | seal vX.Y | check";;
esac
