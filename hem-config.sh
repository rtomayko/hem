#!/bin/sh
# hem-* scripts source this file to bring in some useful helper
# functions.

# Setup some common variables.
progname=$(basename $0)
workdir=$(pwd)
execdir=$(dirname $0)

# These may be inherited from the environment
configfile=
quiet=${quiet:-}

# We assume that the calling script has set USAGE and possibly LONG_USAGE.
[ -n "$LONG_USAGE" ] &&
USAGE="$USAGE
$LONG_USAGE

Copyright (c) 2008, Ryan Tomayko <r@tomayko.com>."

# Quit with non-zero exit code.
die() {
    test $# -gt 0 &&
    echo >&2 "fatal: $progname:" "$@"
    exit 1
}

# Print usage and exit.
usage() {
    echo "Usage: $progname $USAGE"
    exit ${1:-1}
}

# Log a message
log() {
    if [ -n "$log_to" ] ; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') $progname[$$]" "$@" >> "$log_to"
    else
        logger "$@"
    fi
}

# Write non-critical informational message to STDOUT.
info() {
    test -z "$quiet" &&
    echo "$@"
}

# Open an editor with the arguments provided.
editor() {
    test -n "$VISUAL" && $VISUAL "$@"
    ${EDITOR:-'vi'} "$@"
}

# Convert $HOME at the beginning of arg to tilde ("~")
tildize() {
    echo "$1" | sed "s@^$HOME@~@"
    return 0
}

# Don't ever run this file directly.
test "$progname" = "hem-config.sh" &&
die "Try: hem --help"

# Sourcing scripts can set MANUAL_ARGS to have the automatic
# common arg parsing turned off.
: ${MANUAL_ARGS=}

# Check for a -h or --help argument and show usage if found.
if [ -z "$MANUAL_ARGS" ] ; then
    _confnext=
    for i in "$@"
    do
        if [ "$_confnext" = 1 ] ; then
            HEM_DIR="$i"
            _confnext=
        elif [ "$i" = '--config' ] ; then
            _confnext=1
        elif [ "$i" = '--help' ] ; then
            usage 0
        elif [ "$i" = '--' ]; then
            break
        fi
    done
    unset _confnext
fi

HEM_DIR=${HEM_DIR:-~/.hem}

# Use the uid to generate a base monitor port that won't clash with
# others.
default_monitor_port() {
    expr 51243 + $(id -u)
}

# Setup default configuration
configure_defaults() {
    log_to=${log_to:-"$HEM_DIR/log"}
    run_dir=${run_dir:-"$HEM_DIR/run"}
    state_dir=${state_dir:-"$HEM_DIR/state"}
    profile_dir=${conf_dir:-"$HEM_DIR/profile"}
    poll_time=${poll_time:-600}
    ssh_command=${ssh_command:-$(type -P ssh)}
    monitor_port=${monitor_port:-$(default_monitor_port)}
}

need_ssh() {
    ssh_command=${ssh_command:-$(type -P ssh)}
    test -n "$ssh_command" || die "ssh not found."
    return 0
}

hem_config_loaded=
need_config() {
    test -n "$hem_config_loaded" && return 0
    hem_config_loaded=1
    configfile="$HEM_DIR/config"
    test -r "$configfile" || {
        echo >&2 "fatal: $progname: configuration not found: $(tildize $configfile)"
        info "See \`hem init --help\` to initialize a new configuration directory."
        exit 1
    }
    . $configfile
    configure_defaults
    need_ssh
    test -d "$run_dir" || die "bad run_dir: $run_dir"
}


# Profile Helpers =============================================================

# Source a profile into the environment.
profile_with() {
    profile_name="$1"
    profile_file="$profile_dir/$profile_name.conf"
    test -r "$profile_file" ||
    die "profile not found: $profile_file"
    . "$profile_dir/$1.conf"
    profile_host=${host:-$profile_name}
    profile_user=${user:-$LOGNAME}
    profile_port=${port:-22}
    profile_pidfile=${pidfile:-"$run_dir"/$profile_name.pid}
    profile_statefile=${statefile:-"$state_dir"/$profile_name}
    profile_monitor_port=${profile_monitor_port:-0}
    profile_remote="$profile_user@$profile_host:$profile_port"
    unset host user port pidfile statefile
    return 0
}

# Reset all profile variables.
profile_reset() {
    unset profile_name profile_file \
          profile_host profile_user profile_port \
          profile_pidfile profile_statefile
}
