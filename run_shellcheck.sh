#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXEC_FILES=`find "$DIR" ! \( -path "$DIR"/.git -prune \) ! \( -path "$DIR"/vimfiles -prune \) ! \( -path "$DIR"/tools -prune \) ! \( -path "$DIR"/bashscripts -prune \) ! \( -path "$DIR"/poshfiles -prune \) ! \( -path "$DIR"/nvim -prune \) ! \( -path "$DIR"/nuscripts -prune \) ! \( -path "$DIR"/dotbot -prune \) ! \( -path "$DIR"/.testsupport -prune \) -type f -exec sh -c 'head -n1 $1 | grep -qE '"'"'^#!(.*/|\/usr\/bin\/env +)bash'"'" sh {} \; -exec echo {} \;`
SH_FILES=`find "$DIR" ! \( -path "$DIR"/.git -prune \) ! \( -path "$DIR"/vimfiles -prune \) ! \( -path "$DIR"/tools -prune \) ! \( -path "$DIR"/bashscripts -prune \) ! \( -path "$DIR"/poshfiles -prune \) ! \( -path "$DIR"/nvim -prune \) ! \( -path "$DIR"/nuscripts -prune \) ! \( -path "$DIR"/dotbot -prune \) ! \( -path "$DIR"/.testsupport -prune \) -type f -name '*.sh'`
ALL_FILES=`echo -e "$EXEC_FILES\n$SH_FILES" | sort | uniq`
echo -e "Checking files:\n$ALL_FILES"
pushd "$DIR" > /dev/null
# shellcheck disable=SC2086
shellcheck $ALL_FILES
popd > /dev/null
