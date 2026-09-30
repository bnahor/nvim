# hbox image: a disposable Linux dev box with herdvim preinstalled.
# Built by `hbox build` (automatically on first `hbox up`). Build context is the repo root.
#
#   HERDVIM_LSP   language servers to bake in (comma list, or "none")

FROM debian:trixie-slim

ARG HERDVIM_LSP=lua_ls,pyright,ts_ls,marksman
ARG NVIM_VERSION=v0.12.5

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TERM=xterm-256color \
    COLORTERM=truecolor \
    HERDVIM_LSP=${HERDVIM_LSP} \
    HERDVIM_COPILOT=0

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git openssh-client sudo less locales \
      build-essential make unzip gzip tar xz-utils \
      ripgrep fd-find jq \
      python3 python3-pip python3-venv nodejs npm \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/install-tools.sh /tmp/install-tools.sh
RUN PREFIX=/usr/local NVIM_VERSION=${NVIM_VERSION} sh /tmp/install-tools.sh nvim tree-sitter lazygit

# Unprivileged user with passwordless sudo; the box is the isolation boundary.
RUN useradd -m -s /bin/bash -u 1000 dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev \
    && mkdir -p /work && chown dev:dev /work

# Sourced last from the user's .bashrc, because Debian's stock .bashrc resets PS1.
COPY container/profile.sh /etc/profile.d/hbox.sh
RUN echo '. /etc/profile.d/hbox.sh' >>/home/dev/.bashrc

USER dev
WORKDIR /work

# Config last so editing it doesn't invalidate the layers above.
COPY --chown=dev:dev . /home/dev/.config/nvim
RUN rm -rf /home/dev/.config/nvim/.git

# Bake plugins, parsers and language servers into the image so a new box
# starts instantly and works offline.
# `timeout` so an unreachable package can never hang the build.
RUN nvim --headless +qa! \
    && timeout 900 nvim --headless +MasonToolsInstallSync \
         +'lua require("nvim-treesitter").install(require("plugins.treesitter").ensure):wait(600000)' \
         +qa! \
    && test -d ~/.local/share/nvim/site/pack/core/opt/snacks.nvim

CMD ["sleep", "infinity"]
