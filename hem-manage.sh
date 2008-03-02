#!/bin/sh
set -eu
USAGE="[-A][-e] <profile>...
Create connection

  -A, --no-authorize    Don't attempt to push your keys to the remote host's
                        authorized_keys file.
  -e, --edit            Edit profile file(s) after creating (and before
                        authorizing).
      --help            Display this message and exit."

. hem-sh-setup

authorize=1
edit=
while [ $# -gt 0 ] ; do
case "$1" in
	-A|--no-authorize)
		authorize=
		shift
		;;
	-e|--edit)
		edit=1
		shift
		;;
	-*)
		see_usage "illegal argument: $1"
		;;
	*)
		break
		;;
esac
done

# check that <profile> was provided.
[ $# -eq 0 ] &&
see_usage 'profile required'

profile_name="$1"
profile_file=$(profile_path "$profile_name")

if profile_exist "$profile_name"; then
	info "warning: profile exists: $(tildize "$profile_file") (using it)"
else
	remote_part "$profile_name"

	# set misc/other variables
	pidfile="$run_dir/$profile_name.pid"
	statefile="$state_dir/$profile_name"
	monitor_port=0

	mkdir -p "$(dirname "$profile_file")"
	info "writing $profile_file"
	cat <<-EOF > "$profile_file"
	# See hem_profile(5) for information on available options.
	# Profile created by $USER on $(date)

	# The remote location in [user@]host[:port] format. If not set here
	# explicitly, the profile's name ($profile_name) is used.
	#remote="$profile_name"

	# The remote host. This overrides the host in the filename or the remote
	# options.
	#host=$remote_host

	# The remote user/login name. This overrides the username (if any) in the
	# filename or remote option.
	#user=$remote_user

	# The remote SSH port. This overrides the port (if any) in the filename or
	# remote option.
	#port=$remote_port

	# Use this port (and the port immediately following it) to monitoring
	# connection upness.
	#monitor_port=$monitor_port

	# Store the pid file here:
	#pidfile="$pidfile"
	EOF
fi

# kick off editor if requested...
while [ "$edit" = 1 ]; do
	# make a copy in case something gets screwed up
	[ -f "$profile_file+" ] ||
	cp -p "$profile_file" "$profile_file+"
	# launch editor
	editor "$profile_file+"
	# load profile config as a test and also because we may
	# be pushing keys over in a second ...
	if sh -n "$profile_file+"; then
		info 'profile looks good.'
		mv "$profile_file+" "$profile_file"
		edit=
	else
		trap "echo >&2 removing shady profile; rm -f '$profile_file+';exit 1" INT
		info 'errors detected in profile -- press ENTER to fix, interrupt to quit'
		read
	fi
done

if [ $authorize ]; then
	hem-push-keys "$profile_name"
fi

exit 0
