# Allow ANSI "color" escape sequences and exit if entire file can be displayed
# on the first screen
set -x LESS -RF

# Prefer neovim with graceful fallback
if command -q nvim
    set -x EDITOR nvim
else if command -q vim
    set -x EDITOR vim
else
    set -x EDITOR vi
end
