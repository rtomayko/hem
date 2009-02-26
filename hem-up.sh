#!/bin/sh
set -e
USAGE="[-f] <profile>...
Bring up one or more connection profiles.

  -f, --front           Don't background connection. This is typically only
                        useful for debugging configuration problems since
                        error messages are written to stdout.
  -p, --pedantic        Exit with error status if already up.

      --help            Display usage and exit."

. hem-sh-setup

# parse arguments
front=
pedantic=
while [ $# -gt 0 ]; do
case "$1" in
	-f|--front)
		front=1
		shift
		;;
	-p|--pedantic)
		pedantic=1
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

# setup the profile
profile_required "$@"

# check that connection isn't already running.
if quiet=1 hem-status --check "$profile_name" ; then
	info "$profile_name is already up"
	exit 2
fi
info "bringing up: $profile_name"

# write monitor port to state file
mkdir -p "$state_dir"
echo "$monitor_port" > "$statefile"

# Setup autossh environment variables. See autossh(1) for detailed
# descriptions of each. The values below are typically the autossh
# defaults but check the documentation to be sure.
AUTOSSH_DEBUG=$front
AUTOSSH_GATETIME=30
AUTOSSH_LOGLEVEL=5
AUTOSSH_MAXSTART=-1
AUTOSSH_MESSAGE=
#AUTOSSH_PATH="$ssh_command"
AUTOSSH_PIDFILE="$pidfile"
AUTOSSH_POLL=${poll_time:-600}
AUTOSSH_FIRST_POLL=$AUTOSSH_POLL
AUTOSSH_PORT=${monitor_port:-0}

# only set the log file if the log_to variable is set
test -n "$log_to" &&
AUTOSSH_LOGFILE="$log_to"

# export autossh environment
export AUTOSSH_DEBUG AUTOSSH_GATETIME AUTOSSH_LOGLEVEL AUTOSSH_LOGFILE \
	AUTOSSH_PIDFILE AUTOSSH_POLL AUTOSSH_FIRST_POLL AUTOSSH_PORT


# XXX: there's some oddness with setting the AUTOSSH_PORT environment variable
#      to zero that seems to stop autossh from coming up.
if [ "$AUTOSSH_PORT" = 0 ]; then
	unset AUTOSSH_PORT
	export AUTOSSH_PORT
fi

# Build autossh command
command="autossh -M $monitor_port"

# keep autossh in foreground
test -z "$front" &&
command="$command -f"

# going into ssh arguments, don't execute anything and be a control
# master.
command="$command -- -NM"

# remote ssh login name
test "$user" != "$USER" &&
command="$command -l $user"

# remote ssh port
test "$port" != 22 &&
command="$command -p $port"

# tunnels and extra arguments
command="$command $tunnels $extra_args"

# remote host
command="$command $host"

# Log it
log "$command"

if $command ; then
	log "autossh is up"
	exit 0
else
	result=$?
	die "autossh failed with $result"
fi
