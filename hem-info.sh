#!/bin/sh
set -e

USAGE="[OPTIONS] <profile>"
LONG_USAGE="Output configuration information for <profile>.

The following options, when provided, cause each configuration item to
be output on a separate line in the order given.

  -f, --pid-file        output path to pid file
  -F, --profile         output path to profile file
  -m, --monitor         output base monitor port
  -p, --port            output remote SSH port
  -P, --pid             output connection monitor process id
  -r, --remote          output user@host:port
  -t, --host            output remote hostname
  -u, --user            output remote user login
      --help            display help and exit

With no OPTIONS, write the entire profile configuration to standard
output in a format suitable for eval'ing into a shell.
"

. hem-config
need_config

vars=
while [ $# -gt 0 ] ; do
    case "$1" in
        -f|--pid-file)      vars="$vars pidfile" ;;
        -F|--profile)       vars="$vars file" ;;
        -m|--monitor)       vars="$vars monitor_port" ;;
        -p|--port)          vars="$vars port" ;;
        -P|--pid)           vars="$vars pid" ;;
        -r|--remote)        vars="$vars remote" ;;
        -t|--host)          vars="$vars host" ;;
        -u|--user)          vars="$vars user" ;;
        -*)                 echo >&2 "$progname: unknown argument: $1"
                            usage
                            ;;
        *)                  break ;;
    esac
    shift
done

test -z "$1" && usage
profile_name="$1"
shift

test -n "$1" && usage
profile_check $profile_name
profile_with $profile_name

if [ -n "$vars" ] ; then
    for var in $vars ;
    do
        eval "echo \$profile_$var"
    done
else
    echo "# $profile_name: $(tildize $profile_file)"
    set |
    grep '^profile_' |
    grep -v '^profile_dir=' |
    grep -v '^profile_file=' |
    grep -v '^profile_name=' |
    sed 's/^profile_//' |
    sed "s@=$HOME@=~@" |
    sort
fi
