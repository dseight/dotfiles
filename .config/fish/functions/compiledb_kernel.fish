function _compiledb_kernel_usage
    echo "Usage: compiledb_kernel [OPTIONS]"
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
    echo "  -a, --arch ARCH         Target architecture (u-boot only)"
    echo "  --spl                   Use SPL-related entries (u-boot only)"
end

# When building u-boot for something like BeaglePlay (TI AM625) or BeagleY-AI
# (TI AM67), it contains two u-boot builds in the same directory, which will
# lead to having entries arm-...-gcc and aarch64-...-gcc for the same source
# file. More than that, even for the same architecture there could be two
# builds for aarch64 (one is SPL, another one is full-fledged u-boot).
#
# E.g., for the same file (arch/arm/lib/stack.c) there are four entries:
# - arm-...-gcc ... -DCONFIG_SPL_BUILD ... -o spl/arch/arm/lib/stack.o
# - arm-...-gcc ... -o spl/arch/arm/lib/stack.o
# - aarch64-...-gcc ... -DCONFIG_SPL_BUILD ... -o spl/arch/arm/lib/stack.o
# - aarch64-...-gcc ... -o spl/arch/arm/lib/stack.o
#
function _compiledb_kernel_uboot_filter
    set -l out_file $argv[1]
    set -l arch $argv[2]
    set -l spl $argv[3]

    command -q jq
    or echo "Missing jq executable, skipping u-boot fixups" && return 1

    test $spl -eq 0
    and set -l negate_spl ""
    or set -l negate_spl "| not"

    set -l arch_selector "select(.command | startswith(\"$arch-\"))"
    set -l spl_selector "select(.command | contains(\"CONFIG_SPL_BUILD\") $negate_spl)"
    set -l query "[.[] | $arch_selector | $spl_selector]"

    jq $query $out_file > $out_file.jq
    mv $out_file.jq $out_file
end

function compiledb_kernel --description 'Generate compile_commands.json for kernel'
    set -l options h/help b/build= s/source= a/arch= spl
    argparse -n compiledb_kernel $options -- $argv
    or return

    set -q _flag_help
    and _compiledb_kernel_usage && return 0

    set -ql _flag_build
    and set -l build_dir $_flag_build
    or echo "Missing path to the build directory (-b/--build option)" && return 1

    set -ql _flag_source
    and set -l source_dir $_flag_source
    or set -l source_dir $build_dir/source

    set -ql _flag_spl
    and set -l spl 1
    or set -l spl 0

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

    if set -ql _flag_arch
        _compiledb_kernel_uboot_filter $out_file $_flag_arch $spl
    end
end
