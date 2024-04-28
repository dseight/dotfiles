if status is-interactive; and test (uname) = Darwin
    set PATH $PATH \
        $HOME/Library/Android/sdk/platform-tools \
        $HOME/Library/Python/3.9/bin

    if test -x /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    end
end
