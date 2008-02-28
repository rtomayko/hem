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

# Bring in shell helpers
MANUAL_ARGS=1
. hem-config

quiet=
command=
command_args=
profiles=
hem_dir=

# Parse top-level arguments...
while [ $# -gt 0 ]
do
    case "$1" in
        -q|--quiet)  quiet=1 ;;
        -c|--config) die "Sorry, the --config options is not yet implemented.";;
        -*)          usage;;
        *)           break;;
    esac
done

# Bail if no command given..
test $# -eq 0 &&
usage

# Determine command.
command="$1"
shift

# Parse command arguments
while [ $# -gt 0 ]
do
    case "$1" in
        --help) $0-$command --help |
                sed "s/$progname-/$progname /g" |
                sed "s/<profile>$/[<profile> ...]/g"
                exit 1
                ;;
        -*)     command_args="$command_args $1";;
         *)     break;;
    esac
    shift
done

# Special case the init command - it doesn't take any profile arguments.
if [ "$command" = init ] ; then
    exec $0-init $command_args
fi

# Should be safe to bring in config now.
need_config

# Figure out what profiles we're operating on..
if [ $# -gt 0 ] ; then
    profiles="$@"
    for profile in $profiles
    do
        test -r "$profile_dir"/"$profile.conf" ||
        die "no such profile: $profile $(tildize "$profile_dir"/"$profile.conf") not found)"
    done
else
    # No profile names were provided. We need to run the commands on
    # all of them.
    profiles=$(
      (cd "$profile_dir" && /bin/ls -1 *.conf 2>/dev/null) |
      sed 's/\.conf$//'
    )
fi

# Okay, all profiles check out. We loop through each and execute the
# appropriate command:
command="$0-$command"
for profile in $profiles ;
do
    "$command" $command_args "$profile"
done