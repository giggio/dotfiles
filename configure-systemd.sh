#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$BASEDIR"/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please run this script as root"
fi

UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --update|-u)
    UPDATE=true
    shift
    ;;
    --help|-h)
    SHOW_HELP=true
    break
    ;;
    --verbose)
    VERBOSE=true
    shift
    ;;
    *)
    shift
    ;;
  esac
done
eval set -- "$PARSED_ARGS"

if $SHOW_HELP; then
  cat <<EOF
Configures systemd.

Usage:
  `readlink -f $0` [flags]

Flags:
  -u, --update             Will reconfigure systemd even if configuration is already present
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS"
  Update is $UPDATE
fi

NEEDS_RELOAD=false

SERVICE=wsl-clean-memory
SOURCE_SERVICE_FILE="$BASEDIR"/systemd/$SERVICE.service
DESTINATION_SERVICE_FILE=/etc/systemd/system/$SERVICE.service
if ! [ -f $DESTINATION_SERVICE_FILE ] || ! cmp --quiet "$SOURCE_SERVICE_FILE" $DESTINATION_SERVICE_FILE; then
  cp "$SOURCE_SERVICE_FILE" $DESTINATION_SERVICE_FILE
  NEEDS_RELOAD=true
else
  writeBlue "No need to copy $SOURCE_SERVICE_FILE to $DESTINATION_SERVICE_FILE, it already exists and is the same."
fi

SOURCE_TIMER_FILE="$BASEDIR"/systemd/$SERVICE.timer
DESTINATION_TIMER_FILE=/etc/systemd/system/$SERVICE.timer
if ! [ -f $DESTINATION_TIMER_FILE ] || ! cmp --quiet "$SOURCE_TIMER_FILE" $DESTINATION_TIMER_FILE; then
  cp "$SOURCE_TIMER_FILE" $DESTINATION_TIMER_FILE
  NEEDS_RELOAD=true
else
  writeBlue "No need to copy $SOURCE_TIMER_FILE to $DESTINATION_TIMER_FILE, it already exists and is the same."
fi

SOURCE_SCRIPT_FILE="$BASEDIR"/systemd/$SERVICE
DESTINATION_SCRIPT_FILE=/usr/local/sbin/$SERVICE
if ! [ -f $DESTINATION_SCRIPT_FILE ] || ! cmp --quiet "$SOURCE_SCRIPT_FILE" $DESTINATION_SCRIPT_FILE; then
  cp "$SOURCE_SCRIPT_FILE" $DESTINATION_SCRIPT_FILE
  NEEDS_RELOAD=true
else
  writeBlue "No need to copy $SOURCE_SCRIPT_FILE to $DESTINATION_SCRIPT_FILE, it already exists and is the same."
fi

if $NEEDS_RELOAD; then
  systemctl daemon-reload
fi
