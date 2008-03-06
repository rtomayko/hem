#!/bin/sh
#
# hem - ssh controller and automatic tunnel daemon.
#
# Copyright (c) 2008, Ryan Tomayko <r@tomayko.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
set -e

USAGE="[-q][-v][-c <file>] <command> [<opt>]... [<profile>]...
Hem is an ssh controller and tunnel manager.

Available commands:
  init                  initialize the ~/.hem directory
  manage                add a new profile / edit existing profile
  info                  show profile configuration
  status                show connection status

  up                    bring connection profiles up
  down                  take connection profiles down
  bounce                restart connection profiles

Global options:
  -c, --config <file>   load alternative config file
  -q, --quiet           be absolutely quiet
  -v, --verbose         write log messages to stderr
      --version         write program version to stdout and exit
      --help            show usage and exit

See 'hem <command> --help' for information on a specific <command>"

# initialize HEM_DIR and HEM_CONFIG to their default values.
HEM_EXEC=${HEM_EXEC:-"@@HEM_EXEC_DIR@@"}
HEM_VERSION="@@HEM_VERSION@@"
PATH="$HEM_EXEC:$PATH"

. hem-sh-setup

# the default config file location.
HEM_CONFIG=${HEM_CONFIG:-"$HOME/.hem/config"}

# when set, info messages are discarded.
quiet=

# when set, log messages go to stderr along with the log.
verbose=

# commands that do not require valid profile names as arguments.
simple_commands="init list manage help"

# with no arguments, bail out with usage
if [ $# -eq 0 ] ; then
	usage
	exit 1
fi

# parse top-level arguments...
while [ $# -gt 0 ]
do
case "$1" in
	-c|--config)
		HEM_CONFIG="$2"
		shift; shift
		;;
	-q|--quiet)
		quiet=1
		shift
		;;
	-v|--verbose)
		quiet=1
		shift
		;;
	--version)
		echo "Hem $HEM_VERSION"
		exit 0
		;;
	-h|--h*)
		usage
		exit 0
		;;
	-*)
		see_usage "invalid argument: $1"
		;;
	*)
		break
		;;
esac
done

# determine command
command=
if [ $# -gt 0 ]; then
	command="$1"
	shift
else
	see_usage "command not specified."
fi

# verify that command exists
command_path="$HEM_EXEC/hem-$command"
[ -x "$command_path" ] ||
see_usage "unknown command: $command"

[ -n "$(echo "$simple_commands" | grep $command 2>/dev/null)" ] &&
simple_command=1 ||
simple_command=

# parse command arguments
command_argv=
command_help=
profiles=
while [ $# -gt 0 ]; do
case "$1" in
	-h|--hel*)
		command_help=1
		command_argv="$command_argv $1"
		shift
		;;
	--)
		shift
		break
		;;
	-*)
		command_argv="$command_argv $1"
		shift
		;;
	*)
		break
esac
done

# all remaining arguments are profile names. command will be run once
# per profile.
profiles="$@"

# ---------------------------------------------------------------------
# Global Config
# ---------------------------------------------------------------------
#
# Hem's default config file location is ~/.hem/config but it can be
# overridden on the command line or by setting HEM_CONFIG. Hem does not
# require a config file so care must be taken to not assume one
# exists and that defaults are provided.

test -r "$HEM_CONFIG" && {
	__FILE__="$HEM_CONFIG"
	. "$HEM_CONFIG"
	unset __FILE__
}

# configure default config values
hem_dir=$(dirname $HEM_CONFIG)
log_to=${log_to:-}
run_dir=${run_dir:-"$hem_dir/run"}
state_dir=${state_dir:-"$hem_dir/state"}
profile_dir=${profile_dir:-"$hem_dir/profile"}
poll_time=${poll_time:-600}

# setup sub-command environment
export HEM_CONFIG PATH quiet verbose
export log_to run_dir state_dir profile_dir poll_time

# If command help is requested, exec the command immediately.
if [ $command_help ]; then
	exec $command_path --help
fi

# if this is a simple command, invoke it immediately without
# gathering profiles or verifying anything else.
if [ $simple_command ]; then
	exec $command_path $command_argv $profiles
fi

# figure out what profiles we're operating on..
if test -z "$profiles" ||
   test "$profiles" = "--all" ||
   test "$profiles" = "all"
then
	test -d "$profile_dir" &&
	profiles="$( cd "$profile_dir" && ls -1 | grep -v '~$' || true )"
fi

# Loop over selected profiles, kicking off command for each.
failures=0
result=
set +e
for profile in $profiles ;
do
	"$command_path" $command_argv "$profile"
	result=$?
	test "$result" = 1 &&
	failures=$(expr $failures + 1)
done

# exit based on whether any of the commands failed
if [ $failures -gt 1 ] ; then
	die "multiple failures."
elif [ $failures -eq 1 ] ; then
	exit 1
else
	exit 0
fi
