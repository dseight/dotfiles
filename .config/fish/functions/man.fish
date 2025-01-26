function man --wraps man -d "Colored man"
    set -lx LESS_TERMCAP_md (set_color --bold b6a0ff) # mode bold
    set -lx LESS_TERMCAP_me (set_color normal) # mode end
    set -lx LESS_TERMCAP_us (set_color --italics brwhite) # underline start
    set -lx LESS_TERMCAP_ue (set_color normal) # underline end
    set -lx LESS_TERMCAP_so (set_color --reverse dfaf7a) # standout start
    set -lx LESS_TERMCAP_se (set_color normal) # standout end
    set -lx MANPATH $MANPATH
    set -lx MANCOLOR 1

    # prepend the directory of fish manpages to MANPATH
    set -l fish_manpath $__fish_data_dir/man
    if test -d $fish_manpath
        set --prepend MANPATH $fish_manpath:
    end

    command man $argv
end
