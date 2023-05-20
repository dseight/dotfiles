#
# Environment
#

path+=(
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/.scripts"
    "$HOME/.local/bin"
)
if [[ $(uname) = "Darwin" ]]; then
    path+=(
        "$HOME/Library/Android/sdk/platform-tools"
        "$HOME/Library/Python/3.8/bin"
    )
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval $(/opt/homebrew/bin/brew shellenv)
    fi
fi
export PATH

# Allow ANSI "color" escape sequences and exit if entire file can be displayed
# on the first screen
export LESS=-RF

# Prefer neovim with graceful fallback
if which nvim 1>/dev/null 2>&1; then
    export EDITOR=nvim
elif which vim 1>/dev/null 2>&1; then
    export EDITOR=vim
else
    export EDITOR=vi
fi

#
# Completions
#

# Enable completions
autoload -Uz compinit && compinit

# Do menu-driven completion.
zstyle ':completion:*' menu select

# Use ls colors for path completion
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

#
# Prompt
#

# Load vcs info first
autoload -Uz vcs_info

# Color support, like "%{$fg[red]%}"
autoload -Uz colors && colors

# Update PS1 on each command invocation
precmd() {
    vcs_info
    if [[ "${vcs_info_msg_0_}" == ' (git)-[tags/'* ]]; then
        VCS_MSG=" ((${vcs_info_msg_0_:13:-2}))"
    elif [[ "${vcs_info_msg_0_}" == ' (git)-['* ]]; then
        VCS_MSG=" (${vcs_info_msg_0_:8:-2})"
    else
        VCS_MSG="${vcs_info_msg_0_}"
    fi
    PS1="%{$fg[green]%}%n%{$reset_color%}@%m %{$fg[green]%}%~%{$reset_color%}${VCS_MSG}> "
}
