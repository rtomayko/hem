#!/bin/sh
set -e
USAGE="<profile>...
Authorize your public key on the remote host."

. hem-sh-setup

# we need a profile ...
profile_required "$@"

# TODO: which public key to use should be configurable on a global
#       or profile level.
if test -z "$public_key_file" ; then
	if test -r ~/.ssh/id_dsa.pub ; then
		public_key_file=~/.ssh/id_dsa.pub
	elif test -r ~/.ssh/id_rsa.pub ; then
		public_key_file=~/.ssh/id_rsa.pub
	fi
fi

# check that we have a public key and kick off ssh-keygen if not.
# TODO: autogenerating keys should be an option.
if ! test -r "$public_key_file"; then
	info "public key not found ... generating a new one."
	ssh-keygen
fi

info "authorizing on $remote ($(tildize "$public_key_file"))"
public_key="$(cat $public_key_file)"
ssh -l $user -p $port $host '/bin/sh -f' <<EOF
	set -e
	test -d "\$HOME/.ssh" || {
		mkdir ~/.ssh &&
		chmod 0700 ~/.ssh
	}
	if test ! -f "\$HOME/.ssh/authorized_keys" ||
	   test -z "\$(grep -F '$public_key' "\$HOME/.ssh/authorized_keys")" ;
	then
		echo "+++ public key added"
		echo '$public_key' >> "\$HOME/.ssh/authorized_keys"
		exit 0
	else
		echo "+++ public key already authorized."
		exit 1
	fi
EOF
