#!/bin/sh
set -e
USAGE="[<opts>] <profile>...
Output configuration information for <profile>.

The following options, when provided, cause each configuration item to
be output on a separate line in the order given.

  -f, --pid-file        output path to pid file.
  -F, --profile         output path to profile file.
  -m, --monitor         output base monitor port.
  -p, --port            output remote SSH port.
  -r, --remote          output user@host:port.
  -t, --host            output remote hostname.
  -u, --user            output remote user login.
      --help            display help and exit.

With no OPTIONS, write the entire profile configuration to standard
output in a format suitable for eval'ing into a shell."

. hem-sh-setup

vars=
while [ $# -gt 0 ] ; do
case "$1" in
	-f|--pid-file)
		vars="$vars pidfile"
		shift
		;;
	-F|--profile)
		vars="$vars profile_file"
		shift
		;;
	-m|--monitor)
		vars="$vars monitor_port"
		shift
		;;
	-p|--port)
		vars="$vars port"
		shift
		;;
	-r|--remote)
		vars="$vars remote"
		shift
		;;
	-t|--host)
		vars="$vars host"
		shift
		;;
	-u|--user)
		vars="$vars user"
		shift
		;;
	-*)
		see_usage "unknown argument: $1"
		;;
	*)
		break
		;;
esac
done

profile_required "$@"

if [ -n "$vars" ] ; then
	for var in $vars ; do
		eval "echo \$$var"
	done
else
	echo "# $profile_name: $(tildize $profile_file)"
	set |
	grep '^\(host\|port\|user\|remote\|pidfile\|statefile\|monitor_port\|tunnels\|extra_args\|disabled\)=' |
	sed "s@=$HOME@=~@" |
	sort
fi
