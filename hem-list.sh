#!/bin/sh
set -eu
USAGE="
Write available profiles to stdout."

. hem-sh-setup

cd "$profile_dir" &&
ls -1 | grep -v -e '~$' -e '+$' ||
true

exit 0
