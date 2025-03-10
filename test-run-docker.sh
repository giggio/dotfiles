#!/usr/bin/env bash

set -euo pipefail

# build with `docker build -t df .`

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXEC_FILES=$(find "$DIR" ! \( -path "$DIR"/.git -prune \) ! \( -path "$DIR"/vimfiles -prune \) ! \( -path "$DIR"/tools -prune \) ! \( -path "$DIR"/bashscripts -prune \) ! \( -path "$DIR"/poshfiles -prune \) ! \( -path "$DIR"/nvim -prune \) ! \( -path "$DIR"/nuscripts -prune \) ! \( -path "$DIR"/dotbot -prune \) ! \( -path "$DIR"/.testsupport -prune \) -type f -exec sh -c 'head -n1 $1 | grep -qE '"'"'^#!(.*/|\/usr\/bin\/env +)bash'"'" sh {} \; -exec echo {} \;)
SH_FILES=$(find "$DIR" ! \( -path "$DIR"/.git -prune \) ! \( -path "$DIR"/vimfiles -prune \) ! \( -path "$DIR"/tools -prune \) ! \( -path "$DIR"/bashscripts -prune \) ! \( -path "$DIR"/poshfiles -prune \) ! \( -path "$DIR"/nvim -prune \) ! \( -path "$DIR"/nuscripts -prune \) ! \( -path "$DIR"/dotbot -prune \) ! \( -path "$DIR"/.testsupport -prune \) -type f -name '*.sh')
ESCAPED_DIR=$(echo "$DIR" | sed -E 's/\//\\\//g')
ALL_FILES=$(echo -e "$EXEC_FILES\n$SH_FILES" | sort | uniq | sed -E "s/$ESCAPED_DIR\///g")

DOTFILESDIR=/home/user/.dotfiles
V_ARGS=""
for f in $ALL_FILES; do
  V_ARGS="$V_ARGS -v $DIR/$f:$DOTFILESDIR/$f"
done

# shellcheck disable=SC2209
CONTAINER_NAME=df
if [ "$(docker ps --filter name=$CONTAINER_NAME -aq 2> /dev/null)" != '' ]; then
  docker rm -f $CONTAINER_NAME
fi
# shellcheck disable=SC2086
docker run -ti --name $CONTAINER_NAME -v /etc/localtime:/etc/localtime:ro $V_ARGS $CONTAINER_NAME
