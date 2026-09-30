# Shell setup inside an hbox: a prompt in the box's color so it's never
# mistaken for your own machine.
# HBOX_NAME, HBOX_HOST and HERDVIM_COLOR are set by `hbox up`.

[ -n "${BASH_VERSION:-}" ] || return 0

__hbox_color=${HERDVIM_COLOR:-#ffa14f}
__hbox_hex=${__hbox_color#\#}
__hbox_rgb="$((16#${__hbox_hex:0:2}));$((16#${__hbox_hex:2:2}));$((16#${__hbox_hex:4:2}))"
__hbox_label="box:${HBOX_NAME:-$(hostname)}${HBOX_HOST:+@$HBOX_HOST}"

PS1='\[\e[1;38;2;0;0;0;48;2;'"$__hbox_rgb"'m\] 󰆧 '"$__hbox_label"' \[\e[0m\] \[\e[38;2;'"$__hbox_rgb"'m\]\w\[\e[0m\]$(__b=$(git branch --show-current 2>/dev/null) && [ -n "$__b" ] && printf " \001\e[2m\002(%s)\001\e[0m\002" "$__b")\n\[\e[38;2;'"$__hbox_rgb"'m\]❯\[\e[0m\] '

# Window/pane title
PROMPT_COMMAND='printf "\e]2;%s\a" "'"$__hbox_label"' ${PWD/#$HOME/~}"'

export EDITOR=nvim VISUAL=nvim
alias vim=nvim vi=nvim ll='ls -lah'
