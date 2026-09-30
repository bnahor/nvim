# herdvim

A plain Neovim config that uses [herdr](https://herdr.dev) as its terminal
layer. There's no distro and no plugin manager to install: plugins come from
Neovim 0.12's built-in `vim.pack`, pinned by `nvim-pack-lock.json`.

herdr does the pane work. That covers terminals, test runners, AI agents,
containers and remote hosts. Neovim drives it with the `herdr` CLI.

- **One set of arrow keys.** `ctrl+h/j/k/l` moves between Neovim splits and
  crosses into herdr panes at the edge. It works from shells too.
- **Terminals that survive hiding.** `<leader>tt` toggles a shell pane. Hiding
  it moves the pane to a stash tab, so whatever it runs keeps running.
- **Agents beside your code.** Start Claude/Codex/… in a split, prompt it, or
  send it a selection with its file and line numbers.
- **Boxes.** `hbox up` gives you an isolated container with this config inside,
  on your machine or any SSH host with Docker.
- **Remotes.** `hremote HOST` sets up any SSH host (Neovim, tools, this config)
  and opens it.
- **Color tells you where you are.** Local sessions are magenta, local boxes
  orange, SSH hosts cyan and remote boxes violet. The color shows in the
  statusline, the line numbers, the shell prompt and herdr's sidebar.

## Install

Requirements: Neovim **0.12+**, `git`, a C compiler, `tree-sitter` CLI,
`ripgrep`, `fd`, and a [Nerd Font](https://www.nerdfonts.com). herdr and
Docker are optional; without them things fall back to Neovim terminals.

```sh
# macOS
brew install neovim tree-sitter-cli ripgrep fd lazygit
brew install herdr        # or see https://herdr.dev/docs/install

git clone https://github.com/bnahor/nvim ~/src/herdvim
~/src/herdvim/install.sh
```

`install.sh` links the repo to `~/.config/nvim` and moves any existing config
to `~/.config/nvim.bak-<timestamp>`. It also links `hbox`, `hremote` and
`herdr-nav` into `~/.local/bin`. If you don't already have a herdr config, it
links `herdr/config.toml` as yours. Nothing gets deleted.

- **Try it without replacing your config:** `./install.sh --appname herdvim`,
  then run `herdvim`.
- **No sudo or brew:** `./install.sh --tools` installs nvim, tree-sitter, rg, fd
  and lazygit into `~/.local`.

Start herdr (`herdr`) and open `nvim` inside it.

## Keys

`<leader>` is space. `<leader>sk` searches all keymaps, and which-key shows the
rest as you type.

### Moving around (herdr)

| Key | What it does |
| --- | --- |
| `ctrl+h/j/k/l` | Move between splits and panes. Works in Neovim, shells and agents. |
| `ctrl+alt+h/j/k/l` | Always move herdr focus. Use this to leave a box's Neovim. |
| `prefix` = `ctrl+b` | herdr prefix. `prefix+?` lists every binding. |
| `prefix+alt+b` | New box (popup) |
| `prefix+alt+s` | Connect to an SSH host (popup) |
| `prefix+alt+g` | lazygit popup |

### Terminals, runners, agents

| Key | What it does |
| --- | --- |
| `<leader>tt` / `<leader>tv` | Toggle a shell pane below / to the right |
| `<leader>rr` | Run a command in the runner pane |
| `<leader>rl` | Run the last command again |
| `<leader>rf` | Run the current file |
| `<leader>rq` | Load the runner's output into quickfix |
| `<leader>aa` | Start an agent (claude, codex, gemini, …) in a split |
| `<leader>ap` | Prompt an agent |
| `<leader>as` | Send the selection (visual) or `@file:line` (normal) to an agent |
| `<leader>ag` | Jump to an agent |
| `<leader>tz` | Zen mode. Also zooms the herdr pane. |

### Editing

| Key | What it does |
| --- | --- |
| `<leader>sf` / `<leader>sg` | Find files / live grep. Add `-- -g *.lua` to a grep to filter by glob. |
| `<leader>sw` / `<leader>s.` / `<leader><leader>` | Word under cursor / recent files / buffers |
| `<leader>e` / `<leader>E` / `\` | File tree / Oil / reveal the current file |
| `grr` `grd` `gri` `grt` `grn` `gra` | LSP references, definition, implementation, type, rename, code action |
| `<leader>f` | Format |
| `s` / `S` | Flash jump / Flash treesitter |
| `gsa` `gsd` `gsr` | Add / delete / replace surrounding |
| `<leader>gg` | lazygit |
| `]c` `[c` `<leader>h…` | Git hunks |
| `<leader>pu` / `:PackUpdate` | Update plugins. Review, then `:w` to apply or `:q` to cancel. |

## Boxes

```sh
hbox up                       # box for the current dir, mounted at /work/<dir>
hbox up api --copy .          # copy the files in instead, so the box can't touch the originals
hbox up scratch --empty --no-net
hbox up gpu --host rohan-dev  # uses rohan-dev's Docker over SSH; the current dir is copied
hbox ls                       # local boxes and every host you've used
hbox sh api                   # a shell (also: hbox nvim api, hbox stop|start|rm api)
hbox build                    # rebuild the image after changing this config
```

Inside herdr, `hbox up` opens a new workspace named `󰆧 <name>`, colored orange
(violet for a remote box) in the sidebar. Outside herdr you get a shell
directly.

The image comes with Neovim, plugins, parsers and a few language servers baked
in, so boxes start in a second and work offline. Choose the servers with
`HBOX_LSP=pyright,ts_ls hbox build`.

Your git identity comes along, and so does your SSH agent when you use Docker
Desktop or OrbStack.

## Remote hosts

```sh
hremote rohan-dev             # set up on first use, then open a reconnecting SSH shell
hremote setup rohan-dev       # set up and also add it as a herdr machine
hremote sync rohan-dev        # push local config changes
hremote doctor rohan-dev      # what's installed, what's missing
hremote uninstall rohan-dev
```

`hremote` never needs root. It installs Neovim and its tools into `~/.local`.
The config goes in `~/.config/herdvim` and runs as `hv` (`NVIM_APPNAME=herdvim`),
so an existing `~/.config/nvim` on the host is left alone. It also adds a small,
marked block to `~/.bashrc`/`~/.zshrc` for `PATH` and `alias v=hv`.

**Robustness.** Every SSH call uses keepalives, so a dead link gets noticed in
about a minute instead of hanging. One multiplexed connection is shared per
host, so you're asked for credentials at most once. The config is uploaded
atomically (unpacked next to the old copy, then swapped). If the link drops,
the `hremote HOST` shell reconnects with backoff.

**Persistent sessions.** For sessions that survive disconnects, laptop sleep
and network changes, `hremote setup` runs `herdr machine add`. herdr then runs
its own server on the host, shows its workspaces in your sidebar, reconnects
automatically, and keeps agents running while you're away.

Because herdr's config on the host is linked to this one, `ctrl+h/j/k/l` works
there too.

## Layout

```
init.lua                  entry point: load order only
lua/core/options.lua      editor options
lua/core/env.lua          local / box / remote detection and colors
lua/core/pack.lua         vim.pack helpers, build hooks, :Pack* commands
lua/core/herdr.lua        herdr navigation, terminals, runner, agents
lua/core/keymaps.lua      non-plugin keymaps
lua/plugins/*.lua         one file per area: ui, editor, treesitter, lsp, completion, git, files, lang, ai
lua/local.lua             your overrides (git-ignored, loaded last)
herdr/config.toml         herdr keybindings and sidebar colors
bin/                      herdr-nav, hbox, hremote
container/                box image
scripts/install-tools.sh  rootless installer for nvim and friends (used by boxes and remotes)
```

**Adding a plugin:** add it to a `pack.add { … }` list in the right
`lua/plugins/*.lua`, configure it underneath, and restart. `nvim-pack-lock.json`
records the exact revision, so commit it.

**Removing one:** delete it from the config, restart, then run `:PackClean`.

**Language servers:** edit `servers` in `lua/plugins/lsp.lua`. Mason installs
anything missing.

## Navigation details

`ctrl+h/j/k/l` are herdr bindings that run `bin/herdr-nav`. When the focused
pane is running Neovim, the key is passed through to it. Neovim moves between
its own splits and calls `herdr pane focus` when it reaches an edge. In any
other pane, herdr moves focus directly.

- **Shell trade-off:** this is the same trade-off vim-tmux-navigator makes.
  Plain shells don't receive `ctrl+l`, so type `clear` instead.
- **Neovim inside a box:** it can't reach herdr, so `ctrl+h/j/k/l` always move
  herdr focus from a box pane. Use `<C-w>h/j/k/l` for splits inside it.

## Credits

This started as a fork of [iyioon/nvim](https://github.com/iyioon/nvim), which
built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). MIT
licensed.
