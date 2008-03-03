#!/bin/sh
set -e
USAGE="[-s <sig>] <profile>...
Take down one or more connections or send them a specific kill signal.

  -s, --signal <sig>    Take process down with signal <sig>.
      --help            Display usage and exit.

This command exits with a status of 1 when the process does not come
down properly."

. hem-sh-setup

# parse arguments
sig="-TERM"
while [ $# -gt 0 ]; do
case "$1" in
	-s|--signal)
		[ $# -lt 2 ] &&
		see_usage "the --signal argument requires a value."
		sig="$2"
		shift; shift
		;;
	-*)
		see_usage "invalid argument: $1"
		;;
	*)
		break
		;;
esac
done

test $(expr "$sig" : '\-') = 1 ||
sig="-$sig"

# bring in profile settings
profile_required "$@"

# check that connection isn't already running.
pid=$(hem-status --pid "$profile_name")
if [ -z "$pid" ] ; then
	info "$profile_name is already down"
	exit 2
fi

message="taking down: $profile_name (pid: $pid)"
test "$sig" = "-TERM" ||
message="$message with $sig"
info "$message"

command="kill $sig $pid"
log "$command"
if $command ; then
	exit 0
else
	result=$?
	die "kill failed with $result"
fi
