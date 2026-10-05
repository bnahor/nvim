# `nvim` opens inside herdr, starting it if needed (bin/herdr-nvim).
# `command nvim` is always plain Neovim. Sourced from ~/.zshrc by herdvim's install.sh.
nvim() {
  if command -v herdr-nvim >/dev/null 2>&1; then
    herdr-nvim "$@"
  else
    command nvim "$@"
  fi
}
