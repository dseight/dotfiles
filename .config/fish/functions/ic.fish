function _ic_usage
    echo "Usage: ic [OPTIONS] COMMAND"
    echo
    echo "Interactive command editor. Requires fzf."
    echo
    echo "Examples:"
    echo "  ic sed -e {q} file"
    echo
    echo "Options:"
    echo "  -h, --help          Show help"
end

function ic
    set -l options h/help
    argparse -n irg $options -- $argv

    set -q _flag_help
    and _ic_usage && return 0

    set -l left (string split -f1 '{q}' "$argv")
    set -l right (string split -f2 '{q}' "$argv")

    # NOTE: on systems with slow shell startup add something like:
    #       --with-shell "/bin/bash --norc -c"
    printf '' | fzf --disabled --ansi \
        --no-mouse \
        --no-separator \
        --prompt "$left " \
        --info "inline-right:$right " \
        --preview "$argv" \
        --preview-window 'up,99%'
end
