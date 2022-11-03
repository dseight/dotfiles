if status is-interactive
    # Use just 'v' for opening vi-like editor, regardless which one is installed
    if command -q nvim
        abbr -a -g v nvim
    else if command -q vim
        abbr -a -g v vim
    else
        abbr -a -g v vi
    end

    # Use as-tree when searching files with something like fd-find:
    # fd --extension rs | as-tree
    abbr -a -g as-tree tree --fromfile .
end
