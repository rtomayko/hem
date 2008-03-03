#!/bin/sh
set -e
hem_dir=$(echo $(dirname $HEM_CONFIG) | sed "s|^$HOME|~|")
USAGE="[-e][-f][-d <dir>]
Create a configuration directory structure in $hem_dir or the directory
specified in -c <dir>.

  -d, --base-dir <dir>  override default config directory
  -e, --edit            open an editor on the config file after creating
  -f, --force           force overwrite existing configuration

The following files and directories are created:

  $hem_dir/config       hem configuration file.
  $hem_dir/profile      profile directory for storing connection profiles.
  $hem_dir/run          run-time directory for pid and state files."

. hem-sh-setup

# parse arguments
force=
editconfig=
while [ $# -gt 0 ]; do
case "$1" in
	-d|--base-dir)
		test $# -lt 2 &&
		die "missing value to --base-dir argument."
		HEM_CONFIG="$2/config"
		shift; shift
		;;
	-f|--force)
		force=1
		shift
		;;
	-e|--edit)
		editconfig=1
		shift
		;;
	*)
		see_usage "invalid argument: $1"
		;;
esac
done

base_dir=$(dirname $HEM_CONFIG)

# bail if the directory already exists.
test -d "$base_dir" -a -z "$force" &&
die "$base_dir already exists."

if [ -f "$HEM_CONFIG" ]; then
	mv "$HEM_CONFIG" "$HEM_CONFIG~"
	info "backed up $(tildize "$HEM_CONFIG") to $(basename "$HEM_CONFIG")~"
fi

# Create template config file
mkdir -p "$base_dir"
mkdir -p "$base_dir/profile"
mkdir -p "$base_dir/run"
cat <<EOF > "$HEM_CONFIG"
# Hem configuration file (see hem_config(5) for more info)

# Where are profiles stored?
profile_dir=$(tildize $profile_dir)

# Where to write log messages. Leave blank to use the syslog facility.
log_to=$(tildize $log_to)

# Where to put pid files. This directory must exist.
run_dir=$(tildize $run_dir)

# Specifies the connection poll time in seconds; default is 600
# seconds. If the poll time is less than twice the network time-
# outs (default 15 seconds) the network timeouts will be adjusted
# downward to 1/2 the poll time.
poll_time=$poll_time
EOF

if test -n "$editconfig" ; then
	editor "$HEM_CONFIG"
else
	info "edit configuration in: $(tildize "$configfile")"
fi
