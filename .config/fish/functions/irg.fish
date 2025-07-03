function _irg_usage
    echo "Usage: irg [OPTIONS]"
    echo
    echo "Interactive ripgrep. Requires fzf and ripgrep (rg)"
    echo
    echo "Options:"
    echo "  -h, --help          Show help"
end

function irg
    set -l options h/help
    argparse -n irg $options -- $argv

    set -q _flag_help
    and _irg_usage && return 0

    set -l rg (command -s rg)
    or echo "Error: rg executable is missing" && return 1

    set -l editor (command -s $EDITOR)
    or echo "Error: EDITOR environment variable is not set" && return 1

    # Inspired by https://junegunn.github.io/fzf/tips/ripgrep-integration/
    #
    # Preview with cat, highlighting the line in the middle of the window with
    # ripgrep --passthru.
    #
    # NOTE: on machines with slow shell initialization one might want to add
    # something like `--with-shell "/bin/bash --norc -c"`
    #
    printf '' | fzf --disabled --ansi \
        --no-mouse \
        --delimiter : \
        --prompt "rg> " \
        --bind "change:reload:$rg --column --color=always --smart-case -- {q} || :" \
        --bind "enter:become:$editor {1} +{2}" \
        --preview "cat -n {1} | $rg --color=always --passthru '^\s*{2}\s+.*'" \
        --preview-window '+{2}/2,up,55%'
end
