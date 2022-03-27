# Oh My Zsh configuration

export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"

ZSH_THEME="fishy"

# Disable marking untracked files under VCS as dirty. This makes repository
# status check for large repositories much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Extra plugins:
# - https://github.com/zsh-users/zsh-autosuggestions
# - https://github.com/zsh-users/zsh-syntax-highlighting
plugins=(
    git
    tmux
    colored-man-pages
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Common configuration

export PATH="$PATH:$HOME/.local/bin"
export EDITOR=vim

# See https://gnunn1.github.io/tilix-web/manual/vteconfig/
if [[ $TILIX_ID ]] || [[ $VTE_VERSION ]]; then
    source /etc/profile.d/vte.sh
fi

if [[ -f ~/.cargo/env ]]; then
    source ~/.cargo/env
fi

if [[ "$(uname)" = "Darwin" ]]; then
    export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
fi

source ~/.aliases
