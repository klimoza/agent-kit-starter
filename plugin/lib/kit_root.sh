# Sourced by the skills' scripts: find the agent-kit checkout (the repository that holds
# releases/ and templates/). An installed plugin is a copy outside that repository, so the
# checkout is looked up: $AGENT_KIT_DIR, the repository this file lives in, then ~/code.
kit_root() {
  local here c
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  for c in "${AGENT_KIT_DIR:-}" "$here" "$HOME/code/agent-kit" "$HOME/code/agent-kit-starter"; do
    if [ -n "$c" ] && [ -d "$c/releases" ]; then (cd "$c" && pwd); return 0; fi
  done
  echo "no agent-kit checkout found: set AGENT_KIT_DIR to the folder that holds releases/" >&2
  return 1
}
