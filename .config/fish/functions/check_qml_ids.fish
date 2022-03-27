function check_qml_ids --description "Check QML files for unused ids"
    set -l options c/changed
    argparse -n check_qml_ids $options -- $argv
    or return

    set -l files $argv

    if test (count $args) -lt 1
        set files *.qml **/*.qml
    end

    if set -q _flag_changed
        set files (git ls-files -mo | grep -E "\.qml\$")
    end

    for file in $files
        set -l ids (sed -n "s/\s*id:\s*\(\w\)\s*/\1/p" $file)

        for id in $ids
            set -l count (grep -E "[^.]\b$id\b" $file | wc -l)

            if test $count -eq 1
                echo "$file: '$id' seems to be unused"
            end
        end
    end
end
