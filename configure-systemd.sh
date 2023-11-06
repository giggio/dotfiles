#!/usr/bin/env bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

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
  if [ "$EUID" == '0' ]; then
    local USER=''
    local SOURCE_DIR="$BASEDIR"/systemd
    local SCRIPT_DIR=/usr/local/sbin
    local SYSTEMD_DIR=/etc/systemd/system
  else
    local USER='--user'
    local SOURCE_DIR="$BASEDIR"/systemd/user
    local SCRIPT_DIR=$HOME/.local/lib/systemd
    local SYSTEMD_DIR=$HOME/.config/systemd/user
    if ! [ -d "$SCRIPT_DIR" ]; then
      mkdir -p "$SCRIPT_DIR"
    fi
    if ! [ -d "$SYSTEMD_DIR" ]; then
      mkdir -p "$SYSTEMD_DIR"
    fi
  fi
  if ! [ -v 1 ]; then
    die "No service name provided."
  fi
  local SERVICE=$1
  if [[ $SERVICE = *" "* ]]; then
    die "Service name cannot contain spaces."
  fi
  local SOURCE_SERVICE_FILE="$SOURCE_DIR"/$SERVICE.service
  if ! [ -f "$SOURCE_SERVICE_FILE" ]; then
    die "Service file $SOURCE_SERVICE_FILE does not exist."
  fi
  local DESTINATION_SERVICE_FILE=$SYSTEMD_DIR/$SERVICE.service
  # shellcheck disable=SC2086
  if ! [ -f $DESTINATION_SERVICE_FILE ] || ! cmp --quiet "$SOURCE_SERVICE_FILE" $DESTINATION_SERVICE_FILE; then
    if $VERBOSE; then
      writeBlue "Copying $SOURCE_SERVICE_FILE to $DESTINATION_SERVICE_FILE."
    fi
    cp "$SOURCE_SERVICE_FILE" $DESTINATION_SERVICE_FILE
    NEEDS_RELOAD=true
  elif $VERBOSE; then
    writeBlue "No need to copy $SOURCE_SERVICE_FILE to $DESTINATION_SERVICE_FILE, it already exists and is the same."
  fi

  HAS_TIMER=false
  local SOURCE_TIMER_FILE="$SOURCE_DIR"/$SERVICE.timer
  if [ -f "$SOURCE_TIMER_FILE" ]; then
    HAS_TIMER=true
    local DESTINATION_TIMER_FILE=$SYSTEMD_DIR/$SERVICE.timer
    # shellcheck disable=SC2086
    if ! [ -f $DESTINATION_TIMER_FILE ] || ! cmp --quiet "$SOURCE_TIMER_FILE" $DESTINATION_TIMER_FILE; then
      if $VERBOSE; then
        writeBlue "Copying $SOURCE_TIMER_FILE to $DESTINATION_TIMER_FILE."
      fi
      cp "$SOURCE_TIMER_FILE" $DESTINATION_TIMER_FILE
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_TIMER_FILE to $DESTINATION_TIMER_FILE, it already exists and is the same."
    fi
  elif $VERBOSE; then
    writeBlue "No timer file $SOURCE_TIMER_FILE."
  fi

  local SOURCE_SCRIPT_FILE="$SOURCE_DIR"/$SERVICE
  if [ -f "$SOURCE_SCRIPT_FILE" ]; then
    local DESTINATION_SCRIPT_FILE=$SCRIPT_DIR/$SERVICE
    # shellcheck disable=SC2086
    if ! [ -f $DESTINATION_SCRIPT_FILE ] || ! cmp --quiet "$SOURCE_SCRIPT_FILE" $DESTINATION_SCRIPT_FILE; then
      if $VERBOSE; then
        writeBlue "Copying $SOURCE_SCRIPT_FILE to $DESTINATION_SCRIPT_FILE."
      fi
      cp "$SOURCE_SCRIPT_FILE" $DESTINATION_SCRIPT_FILE
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_SCRIPT_FILE to $DESTINATION_SCRIPT_FILE, it already exists and is the same."
    fi
  elif $VERBOSE; then
    writeBlue "No script file $SOURCE_SCRIPT_FILE."
  fi

  SUFFIX=service
  if $HAS_TIMER; then
    SUFFIX=timer
  fi
  if $NEEDS_RELOAD; then
    writeBlue "Reloading systemd."
    systemctl $USER daemon-reload
    writeBlue "Enabling $SERVICE.$SUFFIX..."
    systemctl $USER enable "$SERVICE.$SUFFIX"
  else
    if [ "`systemctl $USER is-enabled "$SERVICE.$SUFFIX"`" != 'enabled' ]; then
      writeBlue "Unit $SERVICE.$SUFFIX is not enabled, enabling..."
      systemctl $USER enable "$SERVICE.$SUFFIX"
    fi
  fi
}

if [ "$EUID" == '0' ]; then
  if $WSL; then
    create_systemd_service_and_timer wsl-clean-memory
    if ! $RUNNING_IN_CONTAINER; then
      create_systemd_service_and_timer wsl-add-winhost
    fi
  fi
  if [ -v SUDO_USER ]; then
    sudo -u "$SUDO_USER" "$BASEDIR"/configure-systemd.sh "$@"
  fi
else
  if $WSL; then
    # create_systemd_service_and_timer wsl-test
    create_systemd_service_and_timer wsl-forward-gpg
  fi
fi
