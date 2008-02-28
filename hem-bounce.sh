#!/bin/sh
set -eu
USAGE="<profile>"
LONG_USAGE="Restart the SSH connection for <profile>"

# Bring in basic sh configuration
. hem-config
need_config

# Grab profile or die
profile_name="$1"
test -z "$profile_name" && usage
shift

# Die if more than one profile provided
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
