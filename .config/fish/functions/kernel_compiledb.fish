function _kernel_compiledb_usage
    echo "Usage: kernel_compiledb [OPTIONS]"
    echo
    echo "Generate compile_commands.json for kernel. The build dir for kernel built with"
    echo "Yocto can be found under something like:"
    echo "  build/tmp/work/beaglebone_yocto-poky-linux-gnueabi/linux-yocto/6.6.21+git/linux-beaglebone_yocto-standard-build"
    echo
    echo "This can also be used for u-boot. The build directory for it can be found under:"
    echo "  build/tmp/work/beaglebone_yocto-poky-linux-gnueabi/u-boot/2024.01/build"
    echo
    echo "Options:"
    echo "  -h, --help              Show help"
    echo "  -b, --build BUILD_DIR   Path to the kernel build dir"
    echo "  -s, --source SRC_DIR    Path to the kernel source dir"
end

function kernel_compiledb --description 'Generate compile_commands.json for kernel'
    set -l options h/help b/build= s/source=
    argparse -n kernel_compiledb $options -- $argv
    or return

    set -q _flag_help
    and _kernel_compiledb_usage && return 0

    set -ql _flag_build
    and set -l build_dir $_flag_build
    or echo "Missing path to the build directory (-b/--build option)" && return 1

    set -ql _flag_source
    and set -l source_dir $_flag_source
    or set -l source_dir $build_dir/source

    test -d $source_dir
    or echo "Invalid path to the source directory (-s/--source option)" && return 1

    set -l build_dir (path resolve $build_dir)
    set -l out_file $source_dir/compile_commands.json

    if test -x $source_dir/scripts/clang-tools/gen_compile_commands.py
        set -f gen_compile_commands $source_dir/scripts/clang-tools/gen_compile_commands.py
    else if test -x $source_dir/scripts/gen_compile_commands.py
        set -f gen_compile_commands $source_dir/scripts/gen_compile_commands.py
    else
        echo "Can't find gen_compile_commands.py"
        return 1
    end

    $gen_compile_commands -d $build_dir -o $out_file
    or return

    sed -i \
        -e "s# -I *\./\([^ ]*/generated[/a-z]*\) # -I$build_dir/\1 #g" \
        -e "s# -fcanon-prefix-map # #g" \
        -e "s# -fcanon-prefix-map # #g" \
        -e "s# -mno-fdpic # #g" \
        -e "s# -fno-ipa-sra # #g" \
        -e "s# -fno-allow-store-data-races # #g" \
        -e "s# -fconserve-stack # #g" \
        -e "s# -mabi=lp64 # #g" \
        -e "s# -mthumb-interwork # #g" \
        -e "s# -mword-relocations # #g" \
        -e "s# -mgeneral-regs-only # #g" \
        $out_file
end
