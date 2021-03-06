set FALLBACK_USER defaultuser
set FALLBACK_HOST 192.168.2.15

function _nemosetup_help
    echo "nemosetup - deploy ssh keys to the Sailfish OS device"
    echo
    echo "USAGE:"
    echo "    nemosetup [OPTIONS] [[USER@]HOST]"
    echo
    echo "USER and HOST could be specified via NEMO_USER and NEMO_HOST"
    echo "environment variables accordingly."
    echo
    echo "OPTIONS:"
    echo "    -p, --pass    Password (defaults to NEMO_PASSWORD env variable)"
    echo "    -h, --help    Print help information"
end

function _nemosetup_internal --no-scope-shadowing
    set -x SSH_ASKPASS $askpass
    set -x SSH_ASKPASS_REQUIRE force

    ssh-copy-id \
        $ssh_options \
        -o PubkeyAuthentication=no \
        -o StrictHostKeyChecking=no \
        $user@$host || return 1

    echo \
"mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat /home/\$LOGNAME/.ssh/authorized_keys > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
rm -f /tmp/rootsetup.sh" \
        | ssh $ssh_options $user@$host "cat > /tmp/rootsetup.sh" \
        || return 1

    echo $password | ssh $ssh_options $user@$host "devel-su sh /tmp/rootsetup.sh" \
        || return 1

    # Unset askpass, otherwise ssh might try to use it for local key
    set -e SSH_ASKPASS
    set -e SSH_ASKPASS_REQUIRE

    # Enable early SSH
    ssh $ssh_options root@$host "mkdir -p /var/lib/environment/usb-moded \
        && echo 'USB_MODED_ARGS=-r' > /var/lib/environment/usb-moded/alwaysdevmode.conf" \
        || return 1
end

function nemosetup --description "Deploy ssh keys to the Sailfish OS device"
    set -l options h/help p/pass=
    argparse -n nemosetup --max-args=1 $options -- $argv
    or return

    if set -q _flag_help
        _nemosetup_help
        return 0
    end

    set -l password $NEMO_PASSWORD
    if set -q _flag_pass
        set password $_flag_pass
    end
    if test -z $password
        echo "Error: password is not set (use -p/--pass option)"
        return 1
    end

    # Try to use user and host from the environment variables first
    set -l user $NEMO_USER
    set -l host $NEMO_HOST

    if set -q argv[1]
        if string match -qr '\w+@\w+' $argv[1]
            set -l remote string split @ $argv[1]
            set user $remote[1]
            set host $remote[2]
        else
            set host $argv[1]
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

    if not ssh-add -l >/dev/null 2>&1
        set -l fallback_keys id_ecdsa id_ed25519 id_ed25519_sk id_rsa

        for key in $fallback_keys
            set -l key_path $HOME/.ssh/$key
            if test -e $key_path
                set ssh_options -i $key_path
                echo "Warning: ssh-agent has no identities, falling back to $key_path"
                break
            end
        end

        if not set -q ssh_options
            set -l ssh_add_cmd "ssh-add"
            if test (uname) = Darwin
                set ssh_add_cmd "ssh-add -K"
            end

            echo "Error: ssh-agent has no identities."
            echo "Consider to run '$ssh_add_cmd' before invoking nemosetup."
            echo "If you have not created any keys yet, run 'ssh-keygen' first."
            return 1
        end
    end

    # "ssh-keygen -R" won't remove key based on the host from ~/.ssh/config
    set -l resolved_host (ssh -G $host | awk '/^hostname / { print $2 }')
    ssh-keygen -R $resolved_host

    set -l askpass (mktemp)

    echo \
"#!/bin/sh
echo $password" > $askpass
    chmod +x $askpass

    _nemosetup_internal

    rm -f $askpass
end

complete -f -c nemosetup -d Remote -xa "(__fish_complete_user_at_hosts)"
complete -f -c nemosetup -s p -l pass -d "Password"
complete -f -c nemosetup -s h -l help -d "Print help information"
