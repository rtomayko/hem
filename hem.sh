#!/bin/sh
#
# hem - SSH controller and automatic tunnel daemon.
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
set -eu

USAGE="[-q] [-c <file>] <command> [<opt> ...] [<profile> ...]"
LONG_USAGE="SSH controller and automatic tunnel daemon.

Available Commands:
  init                  Initialize the ~/.hem directory
  info                  Show profile configuration
  up                    Bring all automatic connections up
  down                  Take all automatic connections down
  bounce                Restart all automatic connections
  status                Show connection status
(Try 'cash <command> --help' for information on a specific command)

Global Options:
  -q, --quiet           Be absolutely quiet.
  -c, --config <file>   Load alternative config file.
      --help            Show usage and exit."

MANUAL_ARGS=1
. hem-sh-setup


quiet=
command=
command_args=
profiles=
hem_dir=

# parse top-level arguments...
while [ $# -gt 0 ]
do
	case "$1" in
		-q|--quiet)
			quiet=1
			;;
		-c|--config)
			die "Sorry, the --config options is not yet implemented."
			;;
		-*)
			usage
			;;
		*)
			break
	esac
	shift
done

# bail if no command given..
test $# -eq 0 &&
usage

# determine command.
command="$1"
shift


# parse command arguments
while [ $# -gt 0 ]
do
	case "$1" in
		--help)
			$0-$command --help |
			sed "s/$progname-/$progname /g" |
			sed "s/<profile>$/[<profile> ...]/g"
			exit 1
			;;
		-*)
			command_args="$command_args $1"
			;;
		*)
			break
	esac
	shift
done

# setup sub-command environment
export quiet

# special case the init command - it doesn't take any profile arguments.
if [ "$command" = init ] ; then
	exec $0-init $command_args
fi

# should be safe to bring in config now.
need_config


# figure out what profiles we're operating on..
group_operation=
if [ $# -gt 0 ] ; then
	profiles="$@"
	for profile in $profiles
	do
		profile_file="$(profile_config_file $profile)"
		profile_okay $profile_file ||
		die "Bad profile: $profile ($(tildize "$profile_file"))"
	done
else
	group_operation=1
	profiles=$( (cd "$profile_dir" && echo * | grep -v '~$') )
	test -z "$profiles" &&
	die "No connection profiles."
	# TODO: info message describing how to setup first profile.
fi

# Make sure command exists
full_command="$0-$command"
if ! type "$full_command" >/dev/null 2>&1 ; then
	usage 1 "unknown command: $command"
fi

# Loop over selected profiles, kicking off command for each.
failures=0
result=
for profile in $profiles ;
do
	if ! "$full_command" $command_args "$profile" ; then
		result=$?
		test $result = 1 &&
		failures=$(expr $failures + 1)
	fi
done

# Exit based on whether the commands
if [ $failures -gt 1 ] ; then
	die "multiple failures."
elif [ $failures -eq 1 ] ; then
	exit 1
else
	exit 0
fi
