#!/bin/sh
set -eu
USAGE="<profile>"
LONG_USAGE="Authorize your public key on the remote host."

# Bring in basic sh configuration
. hem-sh-setup
need_config

# Grab profile or die
profile_name="$1"
test -z "$profile_name" && usage
shift

# Die if more than one profile provided
test $# -gt 0 && usage

profile_with "$profile_name"

# TODO: which public key to use should be configurable on a global
#       or profile level.
profile_public_key_file=${profile_public_key_file:-~/.ssh/id_dsa.pub}

# Check that we have a public key and kick off ssh-keygen if not.
if ! test -r "$profile_public_key_file" ; then
    info "public key not found ... generating a new one."
    ssh-keygen -t dsa
fi

info "authorizing on $profile_remote ($(tildize "$profile_public_key_file"))"
public_key="$(cat $profile_public_key_file)"
ssh -l $profile_user -p $profile_port $profile_host '/bin/sh -f' <<EOF
    set -e
    test -d ~/.ssh || {
        mkdir ~/.ssh &&
        chmod 0700 ~/.ssh
    }
    if test ! -f ~/.ssh/authorized_keys ||
       test -z "\$(grep -F '$public_key' ~/.ssh/authorized_keys)" ;
    then
        echo "+++ public key added"
        echo '$public_key' >> ~/.ssh/authorized_keys
        exit 0
    else
        echo "+++ public key already authorized."
        exit 1
    fi
EOF
