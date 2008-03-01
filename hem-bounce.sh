#!/bin/sh
set -eu
USAGE="<profile>"
LONG_USAGE="Restart the SSH connection for <profile>"

. hem-sh-setup
need_config

profile_name="$1" ; shift
test -z "$profile_name" && usage
test $# -gt 0 && usage

# If the connection is down, bring it up. If its up, restart it with
# a SIGUSR1 signal.
pid=$("$execdir/hem-status" --pid $profile_name)
if [ -n "$pid" ] ;
then
	info "bouncing: $profile_name (pid: $pid)"
	"$execdir/hem-down" -USR2 $profile_name > /dev/null
else
	info "bouncing: $profile_name (fresh)"
	"$execdir/hem-up" $profile_name > /dev/null
fi
