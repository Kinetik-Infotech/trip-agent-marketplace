#!/bin/bash
# Installs Trip Agent on a Mac, in one command:
#
#   curl -fsSL https://raw.githubusercontent.com/Kinetik-Infotech/trip-agent-marketplace/main/install/install.sh | bash
#
# It installs Claude Code's command line if it is missing, checks for Python 3, adds Kinetik's Trip Agent
# listing, installs the plugin, and makes the traveller's folder, ~/trip-agent unless --folder names another.
# The folder's .claude/settings.json names the travel agent, so each Code session started on the folder opens
# with it. Run it again to carry on, or to update: each step already done says so.
#
#   bash install.sh [--folder <folder>] [--marketplace <owner/repo or folder>]
set -u

MARKETPLACE="Kinetik-Infotech/trip-agent-marketplace"
MARKETPLACE_NAME="trip-agent"
PLUGIN="trip-agent"
AGENT="trip-agent:travel-agent"
FOLDER="$HOME/trip-agent"

while [ $# -gt 0 ]; do
  case "$1" in
    --folder) FOLDER="${2:-}"; shift 2 || exit 2 ;;
    --marketplace) MARKETPLACE="${2:-}"; shift 2 || exit 2 ;;
    *) echo "Usage: bash install.sh [--folder <folder>] [--marketplace <owner/repo or folder>]"; exit 2 ;;
  esac
done
case "$FOLDER" in "~/"*) FOLDER="$HOME/${FOLDER#\~/}" ;; esac
if [ "$(uname -s)" != "Darwin" ]; then echo "install.sh is for macOS. On Windows, run install.ps1."; exit 2; fi

LOG="$(umask 077 && mktemp "${TMPDIR:-/tmp}/trip-agent-install-log.XXXXXX")" || { echo "Could not make a log file."; exit 1; }
failed=0
say() { echo "$1: $2"; }

# Claude Code's command line, from Anthropic's own installer, which puts it in ~/.local/bin.
export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
  say "Claude Code" "already there"
elif curl -fsSL https://claude.ai/install.sh | bash >>"$LOG" 2>&1 && command -v claude >/dev/null 2>&1; then
  say "Claude Code" "installed"
else
  say "Claude Code" "failed. Run it by hand: curl -fsSL https://claude.ai/install.sh | bash"
  echo "Then run this again. The log is $LOG."
  exit 1
fi

# Python 3 builds the trip pages and converts prices. A Mac without Apple's command line tools has none, and asking
# for it opens Apple's installer.
if python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
  say "Python 3" "already there"
else
  say "Python 3" "missing. Your Mac may now ask to install its command line developer tools: click Install, wait for it to finish, then run this again"
  xcode-select --install >/dev/null 2>&1
  exit 1
fi

# The listing named trip-agent: ours if it comes from $MARKETPLACE, other if it comes from anywhere else, none if absent.
listing() {
  claude plugin marketplace list --json 2>>"$LOG" | python3 -c '
import json, os, sys
want = sys.argv[1]
for m in json.load(sys.stdin):
    if m.get("name") != "trip-agent":
        continue
    sources = {m.get("repo"), m.get("url"), m.get("path") and os.path.realpath(m["path"])}
    print("ours" if want in sources or os.path.realpath(want) in sources else "other")
    break
else:
    print("none")' "$MARKETPLACE"
}
installed() {
  claude plugin list --json 2>>"$LOG" | python3 -c '
import json, sys
sys.exit(0 if any(p.get("id") == sys.argv[1] for p in json.load(sys.stdin)) else 1)' "$PLUGIN@$MARKETPLACE_NAME"
}

# Kinetik's listing, then the plugin from it.
state="$(listing)"
if [ "$state" = "other" ]; then
  say "Trip Agent listing" "stopped. A listing called $MARKETPLACE_NAME is already there, from somewhere other than $MARKETPLACE. Remove it with: claude plugin marketplace remove $MARKETPLACE_NAME, then run this again"
  exit 1
elif [ "$state" = "ours" ]; then
  claude plugin marketplace update "$MARKETPLACE_NAME" >>"$LOG" 2>&1
  say "Trip Agent listing" "already there, updated"
elif claude plugin marketplace add "$MARKETPLACE" >>"$LOG" 2>&1; then
  say "Trip Agent listing" "added"
else
  say "Trip Agent listing" "failed. Run it by hand: claude plugin marketplace add $MARKETPLACE"
  echo "The log is $LOG."
  exit 1
fi
if installed; then
  claude plugin update "$PLUGIN@$MARKETPLACE_NAME" >>"$LOG" 2>&1
  say "Trip Agent plugin" "already there, updated"
elif claude plugin install "$PLUGIN@$MARKETPLACE_NAME" >>"$LOG" 2>&1; then
  say "Trip Agent plugin" "installed"
else
  say "Trip Agent plugin" "failed. Run it by hand: claude plugin install $PLUGIN@$MARKETPLACE_NAME"
  echo "The log is $LOG."
  exit 1
fi

# The traveller's folder, with the travel agent named in its settings. Any other setting already there is kept.
mkdir -p "$FOLDER/.claude" || { say "Your folder" "failed. Could not make $FOLDER"; exit 1; }
SETTINGS="$FOLDER/.claude/settings.json"
if /usr/bin/env python3 - "$SETTINGS" "$AGENT" <<'PY' >>"$LOG" 2>&1
import json, os, sys
path, agent = sys.argv[1], sys.argv[2]
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)
settings["agent"] = agent
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PY
then
  say "Your folder" "$FOLDER, with the travel agent"
elif [ ! -e "$SETTINGS" ]; then
  printf '{\n  "agent": "%s"\n}\n' "$AGENT" > "$SETTINGS" && say "Your folder" "$FOLDER, with the travel agent"
else
  say "Your folder" "failed. Add \"agent\": \"$AGENT\" to $SETTINGS by hand"
  failed=1
fi

echo
if [ "$failed" = 1 ]; then
  echo "Some steps need finishing. Do what they say, then run this again. The log is $LOG."
  exit 1
fi
echo "Done. In the Claude app's Code tab, start a new session on $FOLDER, and type: Plan me a trip"
