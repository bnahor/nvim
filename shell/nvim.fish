# `nvim` opens inside herdr, starting it if needed (bin/herdr-nvim).
# `command nvim` is always plain Neovim. Installed by herdvim's install.sh.
function nvim --wraps nvim --description 'Neovim, inside herdr'
    if type -q herdr-nvim
        herdr-nvim $argv
    else
        command nvim $argv
    end
end
