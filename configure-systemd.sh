#!/usr/bin/env bash

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
  `readlink -f "$0"` [flags]

Flags:
  -u, --update             Will reconfigure systemd even if configuration is already present
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE"
fi

function create_systemd_service_and_timer {
  local NEEDS_RELOAD=false
  if ! [ -v 1 ]; then
    die "No service name provided."
  fi
  local SERVICE=$1
  if [[ $SERVICE = *" "* ]]; then
    die "Service name cannot contain spaces."
  fi
  local SOURCE_SERVICE_FILE="$BASEDIR"/systemd/$SERVICE.service
  if ! [ -f "$SOURCE_SERVICE_FILE" ]; then
    die "Service file $SOURCE_SERVICE_FILE does not exist."
  fi
  local DESTINATION_SERVICE_FILE=/etc/systemd/system/$SERVICE.service
  # shellcheck disable=SC2086
  if ! [ -f $DESTINATION_SERVICE_FILE ] || ! cmp --quiet "$SOURCE_SERVICE_FILE" $DESTINATION_SERVICE_FILE; then
    cp "$SOURCE_SERVICE_FILE" $DESTINATION_SERVICE_FILE
    NEEDS_RELOAD=true
  elif $VERBOSE; then
    writeBlue "No need to copy $SOURCE_SERVICE_FILE to $DESTINATION_SERVICE_FILE, it already exists and is the same."
  fi

  local SOURCE_TIMER_FILE="$BASEDIR"/systemd/$SERVICE.timer
  if [ -f "$SOURCE_TIMER_FILE" ]; then
    local DESTINATION_TIMER_FILE=/etc/systemd/system/$SERVICE.timer
    # shellcheck disable=SC2086
    if ! [ -f $DESTINATION_TIMER_FILE ] || ! cmp --quiet "$SOURCE_TIMER_FILE" $DESTINATION_TIMER_FILE; then
      cp "$SOURCE_TIMER_FILE" $DESTINATION_TIMER_FILE
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_TIMER_FILE to $DESTINATION_TIMER_FILE, it already exists and is the same."
    fi
  fi

  local SOURCE_SCRIPT_FILE="$BASEDIR"/systemd/$SERVICE
  if [ -f "$SOURCE_SCRIPT_FILE" ]; then
    local DESTINATION_SCRIPT_FILE=/usr/local/sbin/$SERVICE
    # shellcheck disable=SC2086
    if ! [ -f $DESTINATION_SCRIPT_FILE ] || ! cmp --quiet "$SOURCE_SCRIPT_FILE" $DESTINATION_SCRIPT_FILE; then
      cp "$SOURCE_SCRIPT_FILE" $DESTINATION_SCRIPT_FILE
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_SCRIPT_FILE to $DESTINATION_SCRIPT_FILE, it already exists and is the same."
    fi
  fi

  if $NEEDS_RELOAD; then
    systemctl daemon-reload
    # shellcheck disable=SC2086
    systemctl enable $SERVICE.timer
  fi
}

create_systemd_service_and_timer wsl-clean-memory
