set FALLBACK_USER defaultuser
set FALLBACK_HOST 192.168.2.15
set DEPLOYDIR /tmp/deploy

function _nemodeploy_help
    echo "nemodeploy - deploy packages to the Sailfish OS device"
    echo
    echo "USAGE:"
    echo "    nemodeploy [OPTIONS] [PACKAGES...]"
    echo
    echo "By default, all packages from RPMS directory (except *-devel) are "
    echo "sent do the device. Packages could also be specified explicitly."
    echo
    echo "OPTIONS:"
    echo "    -r, --remote    Remote ([user@]host) to install packages to"
    echo "    -h, --help      Print help information"
end

# Send packages to the device (without installing them)
function _nemodeploy_send_packages
    set remote $argv[1]
    set -e argv[1]
    set packages $argv

    if not count $packages >/dev/null
        set packages (find ./RPMS -name '*.rpm' -and -not -name '*-devel-*.rpm')
    end

    ssh $remote "rm -rf $DEPLOYDIR && mkdir -p $DEPLOYDIR"
    scp $packages $remote:$DEPLOYDIR
end

function nemodeploy --description "Deploy packages to the Sailfish OS device"
    set -l options h/help r/remote=
    argparse -n nemodeploy $options -- $argv
    or return

    if set -q _flag_help
        _nemodeploy_help
        return 0
    end

    # Try to use user and host from the environment variables first
    set -l user $NEMO_USER
    set -l host $NEMO_HOST

    if set -q _flag_remote
        if string match -qr '\w+@\w+' $_flag_remote
            set -l remote (string split @ $_flag_remote)
            set user $remote[1]
            set host $remote[2]
        else
            set host $_flag_remote
        end
    end

    if test -z $user
        echo "Warning: user is not set, falling back to '$FALLBACK_USER'"
        set user $FALLBACK_USER
    end

    if test -z $host
        echo "Warning: host is not set, falling back to '$FALLBACK_HOST'"
        set host $FALLBACK_HOST
    end

    _nemodeploy_send_packages $user@$host $argv && \
    ssh root@$host "sh -c \"pkcon install-local -y $DEPLOYDIR/*.rpm\""
end

complete -f -c nemodeploy -s r -l remote -d Remote -xa "(__fish_complete_user_at_hosts)"
complete -f -c nemodeploy -s h -l help -d "Print help information"
