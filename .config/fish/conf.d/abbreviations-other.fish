if status is-interactive
    # Use just 'v' for opening the editor
    abbr -a -g v $EDITOR

    # Use as-tree when searching files with something like fd-find:
    # fd --extension rs | as-tree
    abbr -a -g as-tree tree --fromfile .
end
