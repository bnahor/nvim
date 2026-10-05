#!/usr/bin/env bash
# Install herdvim on this machine.
#
#   ./install.sh                   link this repo as ~/.config/nvim (existing config is backed up)
#   ./install.sh --appname NAME    install side by side as ~/.config/NAME, run with `NAME`
#   ./install.sh --tools           also install nvim/tree-sitter/rg/fd/lazygit into ~/.local if missing
#   ./install.sh --no-herdr        don't touch herdr's config
#   ./install.sh --yes             don't ask before replacing existing configs (they're still backed up)
#
# Everything it replaces is moved to <path>.bak-<timestamp>; nothing is deleted.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
APPNAME=nvim
TOOLS=0
HERDR=1
YES=0
STAMP=$(date +%Y%m%d-%H%M%S)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
BIN=$HOME/.local/bin

while [ $# -gt 0 ]; do
  case $1 in
    --appname) APPNAME=$2; shift 2 ;;
    --tools) TOOLS=1; shift ;;
    --no-herdr) HERDR=0; shift ;;
    --yes | -y) YES=1; shift ;;
    -h | --help) sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

say() { printf '\033[1;35m[herdvim]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[herdvim]\033[0m %s\n' "$*"; }
confirm() {
  [ $YES = 1 ] && return 0
  [ -t 0 ] || return 1
  read -rp "$1 [y/N] " ans
  [[ $ans =~ ^[yY] ]]
}

# Link $2 -> $1, backing up whatever is at $2 unless it's already this link.
link() {
  local src=$1 dst=$2
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    say "backed up $dst -> $dst.bak-$STAMP"
  fi
  ln -s "$src" "$dst"
  say "linked $dst"
}

# --- tools -------------------------------------------------------------------

if [ $TOOLS = 1 ]; then
  PREFIX=$HOME/.local sh "$REPO/scripts/install-tools.sh"
  export PATH="$BIN:$PATH"
fi

missing=()
for t in git nvim tree-sitter rg fd cc curl; do
  command -v "$t" >/dev/null || missing+=("$t")
done
if command -v nvim >/dev/null; then
  if [ "$(nvim --headless +'lua io.write(vim.fn.has("nvim-0.12"))' +qa 2>&1)" != 1 ]; then
    warn "Neovim $(nvim --version | head -n1) is too old: herdvim needs 0.12+ (brew upgrade neovim, or ./install.sh --tools)"
    exit 1
  fi
fi
if [ ${#missing[@]} -gt 0 ]; then
  warn "missing: ${missing[*]}"
  warn "macOS: brew install neovim tree-sitter-cli ripgrep fd  |  anywhere: ./install.sh --tools"
  [[ " ${missing[*]} " == *" nvim "* ]] && exit 1
fi
command -v herdr >/dev/null || warn "herdr not found: everything works, but terminals/agents fall back to Neovim (https://herdr.dev)"

# --- config --------------------------------------------------------------------

target=$CONFIG_HOME/$APPNAME
if [ -e "$target" ] && ! { [ -L "$target" ] && [ "$(readlink "$target")" = "$REPO" ]; }; then
  confirm "Replace $target? (it will be backed up)" || { warn "leaving $target alone; try --appname herdvim"; exit 1; }
fi
link "$REPO" "$target"

mkdir -p "$BIN"
for f in herdr-nav hbox hremote; do
  link "$REPO/bin/$f" "$BIN/$f"
done
case ":$PATH:" in *":$BIN:"*) ;; *) warn "add $BIN to your PATH" ;; esac

if [ "$APPNAME" != nvim ]; then
  printf '#!/bin/sh\nexec env NVIM_APPNAME=%s nvim "$@"\n' "$APPNAME" >"$BIN/$APPNAME"
  chmod +x "$BIN/$APPNAME"
  say "run it with: $APPNAME"
fi

if [ $HERDR = 1 ]; then
  hcfg=$CONFIG_HOME/herdr/config.toml
  if [ ! -e "$hcfg" ] || { [ -L "$hcfg" ] && [ "$(readlink "$hcfg")" = "$REPO/herdr/config.toml" ]; } || confirm "Replace $hcfg with herdvim's? (it will be backed up)"; then
    link "$REPO/herdr/config.toml" "$hcfg"
    command -v herdr >/dev/null && herdr server reload-config >/dev/null 2>&1 || true
  else
    warn "kept your herdr config; see $REPO/herdr/config.toml for the bindings herdvim expects"
  fi
fi

if [ $HERDR = 1 ] && command -v herdr >/dev/null; then
  # Tab completion for the herdr CLI.
  if command -v fish >/dev/null; then
    mkdir -p "$CONFIG_HOME/fish/completions"
    herdr completion fish >"$CONFIG_HOME/fish/completions/herdr.fish"
  fi
  # Agent integrations: agents report their exact state to herdr and resume
  # their conversation after a herdr restart. Each adds a hook to that agent's
  # own config, so ask first. (target:command)
  agents=""
  for pair in claude:claude codex:codex cursor:cursor-agent opencode:opencode pi:pi devin:devin copilot:copilot antigravity-cli:agy; do
    command -v "${pair#*:}" >/dev/null && agents="$agents ${pair%%:*}"
  done
  if [ -n "$agents" ] && confirm "Install herdr integrations for:$agents? (adds a hook to each agent's config)"; then
    for a in $agents; do
      if herdr integration install "$a" >/dev/null 2>&1; then
        say "herdr integration: $a"
      else
        warn "herdr integration for $a didn't install; run 'herdr integration install $a' to see why"
      fi
    done
  fi
fi

# --- plugins ---------------------------------------------------------------------

say "installing plugins (vim.pack, pinned by nvim-pack-lock.json)…"
NVIM_APPNAME=$APPNAME nvim --headless +qa! 2>&1 | grep -v '^vim.pack' | grep -v '^\[nvim-treesitter' || true
say "done. Language servers install in the background on first start (:Mason to watch)."
