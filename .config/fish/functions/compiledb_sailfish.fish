# Fix paths and remove unsupported compiler options in compilation database.
function _fixup_compilation_database
    set compiledb_path $argv[1]
    set -e argv[1]

    # At first we remove here all messages like "Mounting system directories..."
    # by grepping for a line with path. It is required when using native SDK.
    # Then, we remove ^M character with tr (on Darwin, output from ssh contains
    # this character)
    set real_usr (sb2 sb2-show which /usr | grep "^/" | tr -d '\015')

    if test "$SFOSSDK_USE_VM" = "y"
        set real_usr (echo "$real_usr" | perl -pe "s;/srv/mer;$MERSDK_VM_ROOT/mersdk;")
        perl -i -pe "s;/home/mersdk/share;$HOME;g" "$compiledb_path"
    end

    set tmp "$compiledb_path.$fish_pid"

    # Yep, I am certanly understand that bundling Python script into a fish one
    # is freakin' ugly. But it makes distribution easier.
    python3 -c "
#!/usr/bin/env python3

import argparse
import glob
import json
import os
import re
import shlex
import sys
from typing import List, Iterable

UNSUPPORTED_OPTIONS = frozenset((
    '-mfloat-abi=hard',
    '-mfpu=neon',
    '-mthumb',
    '-Wno-psabi',
    '-march=armv7-a',
    '-march=armv8-a',
    '-fstack-clash-protection',
    '-Wl,-z,relro,-z,now',
))


def fix_include_path(path, usr_path):
    # Sometimes there is a double slash ('//') in the beginning of include path
    # (e.g. '//usr' instead of '/usr').
    return re.sub(r'/+usr', usr_path, path)


def locate_std_cpp_includedir(usr_path):
    dirs = glob.glob(usr_path + '/include/c++/*')
    if dirs:
        # We have to return target-anchored path so it could be fixed by
        # fix_include_path() later
        return dirs[0].replace(usr_path, '/usr')
    else:
        return None


def find_cross_target(usr_path):
    # Ugly heuristic for cross target detection
    dirs = glob.glob(usr_path + '/include/c++/*/*/bits/c++config.h')
    if dirs:
        cross_path = dirs[0].replace(usr_path, '/usr').replace('/bits/c++config.h', '')
        return os.path.basename(cross_path)
    else:
        return None


def fix_arguments_list(args: List[str], usr_path, store_cross_target) -> Iterable[str]:
    args = args.copy()

    # Drop ccache to fix compiler detection
    if args[0] == 'ccache':
        del args[0]

    # Some tools may fail to autodetect compiler
    if args[0] == '/usr/bin/cc' or args[0] == 'cc':
        args[0] = 'gcc'
    elif args[0] == '/usr/bin/c++' or args[0] == 'c++':
        args[0] = 'g++'

    # Usually, arguments list does not contain path to system includes
    args.insert(1, '-isystem')
    args.insert(2, '/usr/include')

    cross_target = find_cross_target(usr_path)
    if cross_target and store_cross_target:
        args.insert(1, '-target')
        args.insert(2, cross_target)

    # Add path to C++ std library, so analyzers will be able to find headers
    # like '<memory>'
    if args[0] == 'g++':
        includedir = locate_std_cpp_includedir(usr_path)

        if includedir:
            args.insert(1, '-isystem')
            args.insert(2, includedir)

            if cross_target:
                args.insert(3, '-isystem')
                args.insert(4, includedir + '/' + cross_target)

    # Fix ARM includes
    if '-D__ARM_PCS_VFP' not in args:
        args.insert(1, '-D__ARM_PCS_VFP')

    for i in range(len(args)):
        arg = args[i]
        if arg == '-isystem':
            args[i + 1] = fix_include_path(args[i + 1], usr_path)
        elif arg.startswith('-I'):
            args[i] = '-I' + fix_include_path(arg[2:], usr_path)

    # Filter out all unsupported compiler options
    return filter(lambda op: op not in UNSUPPORTED_OPTIONS, args)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--usr',
                        default='/srv/mer/targets/SailfishOS-latest-armv7hl/usr',
                        help='Path to target /usr directory, usually can be retrieved with \"sb2 sb2-show which /usr\"')
    parser.add_argument('--store-cross-target', action='store_true',
                        help='Store -target option in compilation database')
    args = parser.parse_args()

    compiledb = json.load(sys.stdin)

    for entry in compiledb:
        arguments = None

        if 'arguments' in entry:
            arguments = entry['arguments']

            # Fix CMake-generated compilation database
            if len(arguments) == 1:
                arguments = shlex.split(arguments)

            del entry['arguments']

        # meson generates database with 'command' instead of 'arguments'
        if 'command' in entry:
            arguments = shlex.split(entry['command'])

        if not arguments:
            continue

        arguments = fix_arguments_list(arguments, args.usr, args.store_cross_target)

        # Prefer 'command' over 'arguments', as clang's analyze-build does not
        # understand how to read 'arguments'
        entry['command'] = shlex.join(arguments)

    json.dump(compiledb, sys.stdout, indent=2)
" -u $real_usr $argv < $compiledb_path > $tmp

    mv $tmp $compiledb_path
end

# Generate compilation database.
# May be useful for dealing with qmake projects in something like CLion.
function compiledb_sailfish
    sb2 compiledb -n -f make
    _fixup_compilation_database compile_commands.json $argv
end

complete -f -c compiledb_sailfish -l store-cross-target -d "Store -target option in compilation database"
