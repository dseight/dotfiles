function _ised_usage
    echo "Usage: ised [OPTIONS]"
    echo
    echo "Interactive sed. Requires fzf."
    echo
    echo "Options:"
    echo "  -h, --help          Show help"
end

function ised
    set -l options h/help
    argparse -n irg $options -- $argv

    # TODO: remove -I/-i options

    set -q _flag_help
    and _ised_usage && return 0

    printf '' | fzf --disabled --ansi \
        --no-mouse \
        --info hidden \
        --no-separator \
        --prompt "sed -e " \
        --preview "sed -e {q} $argv" \
        --preview-window 'up,99%'
end
