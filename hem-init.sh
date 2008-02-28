#!/bin/sh
USAGE="[-f] [-e] [-c <dir>]"
LONG_USAGE="Initialize a template configuration directory structure in <dir>.

  -c <dir>         Specify the configuration directory (default: ~/.hem)
  -e               Open an editor on the config file after creating
  -f               Force overwrite existing configuration"

. hem-sh-setup

set -e

configure_defaults
need_ssh

force=
editconfig=
while getopts efqc: o
do
    case "$o" in
        f)   force=1;;
        q)   quiet=1;;
        e)   editconfig=1;;
        [?]) usage;;
    esac
done

# Bail if the directory already exists.
test -d "$HEM_DIR" -a -z "$force" &&
die "$HEM_DIR already exists."

info "Creating template structure under $(tildize $HEM_DIR) ..."

# Create directories ...
mkdir -p "$HEM_DIR"     && info "mkdir $(tildize "$HEM_DIR")"
mkdir -p "$run_dir"     && info "mkdir $(tildize "$run_dir")"
mkdir -p "$profile_dir" && info "mkdir $(tildize "$profile_dir")"
mkdir -p "$state_dir"   && info "mkdir $(tildize "$state_dir")"
test -n "$log_to" &&
touch "$log_to" &&
info "touch $log_to"

configfile="$HEM_DIR/config"
if test -f "$configfile" ; then
    mv "$configfile" "${configfile}~"
    info "backed up $(tildize "$configfile") to $(basename "$configfile")~"
fi

# Create template config file
cat <<-EOF > "$configfile"
# hem configuration file

# Where to write log messages. Leave blank to use the syslog facility.
log_to=$(tildize $log_to)

# Where to put pid files. This directory must exist.
run_dir=$(tildize $run_dir)

# Specifies the connection poll time in seconds; default is 600
# seconds. If the poll time is less than twice the network time-
# outs (default 15 seconds) the network timeouts will be adjusted
# downward to 1/2 the poll time.
poll_time=$poll_time

# The path to the ssh command to execute. Leave blank to use the
# first ssh found on PATH.
ssh_command=$ssh_command

# The first monitor port. Each connection uses two monitor ports. You
# should pick a port in the range 49152..65535, making sure to leave
# room for each set of connections.
monitor_port=$monitor_port

# vim: ft=sh
EOF

if test -n "$editconfig" ; then
    editor "$configfile"
else
    info "Edit configuration in: $(tildize "$configfile")"
fi
