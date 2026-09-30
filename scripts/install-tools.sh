#!/bin/sh
# Install the command-line tools herdvim needs into a prefix, without root.
# Used by the box image (PREFIX=/usr/local) and by `hremote setup` on SSH hosts
# (PREFIX=~/.local). Safe to re-run: tools already at the right version are skipped.
#
#   PREFIX=~/.local sh scripts/install-tools.sh [nvim] [tree-sitter] [rg] [fd] [lazygit]
#
# With no arguments, installs everything that's missing.
set -eu

PREFIX=${PREFIX:-$HOME/.local}
NVIM_VERSION=${NVIM_VERSION:-v0.12.5}
BIN=$PREFIX/bin
OPT=$PREFIX/opt
mkdir -p "$BIN" "$OPT"

log() { printf '\033[1;35m[herdvim]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[herdvim]\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
# Installed already, either in PREFIX (often not on PATH over non-interactive SSH) or elsewhere.
present() { [ -x "$BIN/$1" ] || have "$1"; }

fetch() { # url dest
  if have curl; then
    curl -fsSL --retry 3 --retry-delay 2 -o "$2" "$1"
  elif have wget; then
    wget -q -O "$2" "$1"
  else
    die "need curl or wget"
  fi
}

os=$(uname -s)
case $(uname -m) in
  x86_64 | amd64) arch=x86_64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) die "unsupported CPU: $(uname -m)" ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Latest release asset URL from GitHub matching a pattern.
gh_asset() { # repo regex
  fetch "https://api.github.com/repos/$1/releases/latest" "$tmp/rel.json"
  grep -o '"browser_download_url": *"[^"]*"' "$tmp/rel.json" | cut -d'"' -f4 | grep -E "$2" | head -n1
}

install_nvim() {
  if [ -x "$BIN/nvim" ] && "$BIN/nvim" --version 2>/dev/null | head -n1 | grep -q "NVIM ${NVIM_VERSION}"; then
    return
  fi
  case $os in
    Linux) name=nvim-linux-$arch ;;
    Darwin) name=nvim-macos-$arch ;;
    *) die "unsupported OS: $os" ;;
  esac
  log "installing Neovim $NVIM_VERSION"
  fetch "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$name.tar.gz" "$tmp/nvim.tgz"
  rm -rf "$OPT/nvim"
  mkdir -p "$OPT/nvim"
  tar -xzf "$tmp/nvim.tgz" -C "$OPT/nvim" --strip-components=1
  ln -sf "$OPT/nvim/bin/nvim" "$BIN/nvim"
}

install_tree_sitter() {
  present tree-sitter && return
  case $os-$arch in
    Linux-x86_64) a=linux-x64 ;;
    Linux-arm64) a=linux-arm64 ;;
    Darwin-x86_64) a=macos-x64 ;;
    Darwin-arm64) a=macos-arm64 ;;
  esac
  log "installing tree-sitter CLI"
  fetch "$(gh_asset tree-sitter/tree-sitter "tree-sitter-$a\\.gz$")" "$tmp/ts.gz"
  gunzip -c "$tmp/ts.gz" >"$BIN/tree-sitter"
  chmod +x "$BIN/tree-sitter"
}

# Rust tools publish "<name>-<ver>-<triple>.tar.gz" with the binary one level down.
install_rust_tool() { # repo binary
  present "$2" && return
  case $os-$arch in
    Linux-x86_64) triple=x86_64-unknown-linux-musl ;;
    Linux-arm64) triple='aarch64-unknown-linux-(gnu|musl)' ;;
    Darwin-x86_64) triple=x86_64-apple-darwin ;;
    Darwin-arm64) triple=aarch64-apple-darwin ;;
  esac
  log "installing $2"
  fetch "$(gh_asset "$1" "$triple\\.tar\\.gz$")" "$tmp/$2.tgz"
  mkdir -p "$tmp/$2"
  tar -xzf "$tmp/$2.tgz" -C "$tmp/$2"
  find "$tmp/$2" -type f -name "$2" -exec cp {} "$BIN/$2" \;
  chmod +x "$BIN/$2"
}

install_lazygit() {
  present lazygit && return
  case $os in Linux) o=linux ;; Darwin) o=darwin ;; esac
  log "installing lazygit"
  fetch "$(gh_asset jesseduffield/lazygit "_${o}_$arch\\.tar\\.gz$")" "$tmp/lg.tgz"
  tar -xzf "$tmp/lg.tgz" -C "$BIN" lazygit
}

[ $# -eq 0 ] && set -- nvim tree-sitter rg fd lazygit
for tool in "$@"; do
  case $tool in
    nvim) install_nvim ;;
    tree-sitter) install_tree_sitter ;;
    rg) install_rust_tool BurntSushi/ripgrep rg ;;
    fd) install_rust_tool sharkdp/fd fd ;;
    lazygit) install_lazygit ;;
    *) die "unknown tool: $tool" ;;
  esac
done
