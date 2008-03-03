#!/bin/sh
set -e
USAGE="<profile>...
Restart the ssh connection for <profile>."

. hem-sh-setup

profile_required "$@"

# If the connection is down, bring it up. If its up, restart it with
# a SIGUSR1 signal.
pid=$(hem-status --pid $profile_name)
if [ -n "$pid" ]; then
	info "bouncing: $profile_name (pid: $pid)"
	quiet=1 hem-down --signal USR2 "$profile_name"
else
	info "bouncing: $profile_name (fresh)"
	quiet=1 hem-up $profile_name
fi
