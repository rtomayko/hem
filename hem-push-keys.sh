#!/bin/sh
set -eu
USAGE="<profile>...
Authorize your public key on the remote host."

. hem-sh-setup

# we need a profile ...
profile_required "$@"

# TODO: which public key to use should be configurable on a global
#       or profile level.
public_key_file=${public_key_file:-~/.ssh/id_dsa.pub}

# check that we have a public key and kick off ssh-keygen if not.
# TODO: autogenerating keys should be an option.
if ! test -r "$public_key_file"; then
	info "public key not found ... generating a new one."
	ssh-keygen -t dsa
fi

info "authorizing on $remote ($(tildize "$public_key_file"))"
public_key="$(cat $public_key_file)"
ssh -l $user -p $port $host '/bin/sh -f' <<EOF
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
