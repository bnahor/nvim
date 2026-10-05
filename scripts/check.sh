#!/bin/sh
# Boots herdvim in a real terminal (a detached tmux session) and fails if
# anything went wrong on the way up.
#
# `nvim --headless` isn't enough: UIEnter and VimEnter-with-a-UI never fire
# there, and that's where the dashboard and most UI plugins start. This runs
# the config the way you do, then reads :messages back out.
#
#   scripts/check.sh            the config in this directory
set -eu

command -v tmux >/dev/null || { echo "check.sh needs tmux" >&2; exit 2; }

here="$(cd "$(dirname "$0")/.." && pwd)"
session="herdvim-check-$$"
out="$(mktemp)"
trap 'tmux kill-session -t "$session" 2>/dev/null || true; rm -f "$out"' EXIT

tmux new-session -d -s "$session" -x 160 -y 45 "cd '$here' && nvim"
sleep 5
# :messages holds every error and warning raised during startup, including
# ones from autocommands that only run with a UI attached.
tmux send-keys -t "$session" -l ":redir! > $out | silent messages | redir END"
tmux send-keys -t "$session" Enter
sleep 1
tmux send-keys -t "$session" -l ":qa!"
tmux send-keys -t "$session" Enter
sleep 1

if grep -qE 'E[0-9]+:|[Ee]rror|stack traceback' "$out"; then
  echo "herdvim: startup reported problems:" >&2
  cat "$out" >&2
  exit 1
fi
echo "herdvim: started cleanly"
