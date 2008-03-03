#!/bin/sh
set -e
USAGE="[-c][-p] <profile>...
Show connection status information for <profile>; or, if a single <profile>
'all' is supplied, show status of all connections.

  -c, --check           exit with status 1 if down.
  -p, --pid             write the profile's PID to stdout. If down, no
                        output is generated.
      --help            display help and exit.

When neither --check or --pid are specified, output a description of
the connection status. The format varies based on the connection state."

. hem-sh-setup

# parse arguments
check_mode=
output_pid=
while [ $# -gt 0 ] ; do
case "$1" in
	-c|--check)
		check_mode=1
		shift
		;;
	-p|--pid)
		output_pid=1
		shift
		;;
	-*)
		see_usage "invalid argument: $1"
		shift
		;;
	*)
		break
		;;
esac
done

profile_required "$@"

# get some info on our process
pidfile_ok=n
pid_ok=n
pid=
if [ -r "$pidfile" ] ; then
	pidfile_ok=y
	pid=$(cat $pidfile)
	[ -n "$(ps -p $pid | grep $pid)" ] && pid_ok=y
fi

# determine process status
case "$pidfile_ok,$pid_ok" in
	y,y) process_status="up";;
	n,n) process_status="down";;
	y,n) process_status="stale";;
	n,y) process_status="wtf";;
esac

# output the PID if --pid was given or a longer status if --check was not.
if [ $output_pid ] ; then
	test $pid_ok = y &&
	echo $pid
elif [ ! $check_mode ] ; then
	[ $quiet ] ||
	printf "%-45s%-10s%6s\n" "$profile_name" "$process_status" "$pid"
fi

# if --check was given, exit accordingly.
if [ $check_mode ] ; then
	[ $pid_ok = y ] &&
	exit 0 ||
	exit 1
fi
