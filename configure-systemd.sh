#!/usr/bin/env bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if $ANDROID; then
  writeGreen "Not running configure-systemd.sh because this is Android."
  exit
fi

SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help | -h)
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
  cat << EOF
Configures systemd.

Usage:
  $(readlink -f "$0") [flags]

Flags:
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  User is $(whoami) ($EUID)"
  if [ -v DBUS_SESSION_BUS_ADDRESS ]; then
    writeGreen "  DBUS_SESSION_BUS_ADDRESS is $DBUS_SESSION_BUS_ADDRESS"
  else
    writeGreen "  DBUS_SESSION_BUS_ADDRESS is not set"
  fi
  if [ -v XDG_RUNTIME_DIR ]; then
    writeGreen "  XDG_RUNTIME_DIR is $XDG_RUNTIME_DIR"
  else
    writeGreen "  XDG_RUNTIME_DIR is not set"
  fi
fi

function create_systemd_service_and_timer {
  local NEEDS_RELOAD=false
  if [ "$EUID" != '0' ]; then
    die "Use nix to create systemd user services, sockets etc."
  fi
  local SOURCE_DIR="$BASEDIR"/systemd
  local SCRIPT_DIR=/usr/local/sbin
  local SYSTEMD_DIR=/etc/systemd/system
  if ! [ -v 1 ]; then
    die "No service name provided."
  fi
  local SERVICE=$1
  if [[ $SERVICE = *" "* ]]; then
    die "Service name cannot contain spaces."
  fi

  local SOURCE_SERVICE_FILE="$SOURCE_DIR"/$SERVICE.service
  # shellcheck disable=SC2086
  if ! [ -f $SOURCE_SERVICE_FILE ]; then
    SOURCE_SERVICE_FILE="$SOURCE_DIR"/$SERVICE@.service
  fi
  local IS_TEMPLATE_SERVICE=false
  if [ -f "$SOURCE_SERVICE_FILE" ]; then
    if [[ $SOURCE_SERVICE_FILE = *"@"* ]]; then
      IS_TEMPLATE_SERVICE=true
      local DESTINATION_SERVICE_FILE=$SYSTEMD_DIR/$SERVICE@.service
    else
      local DESTINATION_SERVICE_FILE=$SYSTEMD_DIR/$SERVICE.service
    fi
    # local DESTINATION_SERVICE_FILE=$SYSTEMD_DIR/$SERVICE.service
    if ! [ -f "$DESTINATION_SERVICE_FILE" ] || ! cmp --quiet "$SOURCE_SERVICE_FILE" "$DESTINATION_SERVICE_FILE"; then
      if $VERBOSE; then
        writeBlue "Copying $SOURCE_SERVICE_FILE to $DESTINATION_SERVICE_FILE."
      fi
      cp "$SOURCE_SERVICE_FILE" "$DESTINATION_SERVICE_FILE"
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_SERVICE_FILE to $DESTINATION_SERVICE_FILE, it already exists and is the same."
    fi
  fi

  HAS_TARGET=false
  local SOURCE_TARGET_FILE="$SOURCE_DIR"/$SERVICE.target
  if [ -f "$SOURCE_TARGET_FILE" ]; then
    HAS_TARGET=true
    local DESTINATION_TARGET_FILE=$SYSTEMD_DIR/$SERVICE.target
    # shellcheck disable=SC2086
    if ! [ -f $DESTINATION_TARGET_FILE ] || ! cmp --quiet "$SOURCE_TARGET_FILE" $DESTINATION_TARGET_FILE; then
      if $VERBOSE; then
        writeBlue "Copying $SOURCE_TARGET_FILE to $DESTINATION_TARGET_FILE."
      fi
      cp "$SOURCE_TARGET_FILE" $DESTINATION_TARGET_FILE
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_TARGET_FILE to $DESTINATION_TARGET_FILE, it already exists and is the same."
    fi
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
  HAS_SOCKET=false
  local SOURCE_SOCKET_FILE="$SOURCE_DIR"/$SERVICE.socket
  if [ -f "$SOURCE_SOCKET_FILE" ]; then
    HAS_SOCKET=true
    local DESTINATION_SOCKET_FILE=$SYSTEMD_DIR/$SERVICE.socket
    # shellcheck disable=SC2086
    if ! [ -f $DESTINATION_SOCKET_FILE ] || ! cmp --quiet "$SOURCE_SOCKET_FILE" $DESTINATION_SOCKET_FILE; then
      if $VERBOSE; then
        writeBlue "Copying $SOURCE_SOCKET_FILE to $DESTINATION_SOCKET_FILE."
      fi
      cp "$SOURCE_SOCKET_FILE" $DESTINATION_SOCKET_FILE
      NEEDS_RELOAD=true
    elif $VERBOSE; then
      writeBlue "No need to copy $SOURCE_SOCKET_FILE to $DESTINATION_SOCKET_FILE, it already exists and is the same."
    fi
  elif $VERBOSE; then
    writeBlue "No socket file $SOURCE_SOCKET_FILE."
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

  local SUFFIX
  if $HAS_TARGET; then
    SUFFIX=target
  elif $HAS_TIMER; then
    SUFFIX=timer
  else
    SUFFIX=service
  fi
  if $NEEDS_RELOAD; then
    writeBlue "Reloading systemd."
    systemctl daemon-reload
  fi
  if ! $IS_TEMPLATE_SERVICE; then
    if [ "$(systemctl is-enabled "$SERVICE.$SUFFIX")" != 'enabled' ]; then
      writeBlue "Unit $SERVICE.$SUFFIX is not enabled, enabling..."
      # disable first so if it had different dependents they will be removed
      systemctl disable "$SERVICE.$SUFFIX"
      systemctl enable "$SERVICE.$SUFFIX"
    fi
  fi
  if $HAS_SOCKET; then
    if [ "$(systemctl is-enabled "$SERVICE.socket")" != 'enabled' ]; then
      writeBlue "Enabling $SERVICE.socket..."
      # disable first so if it had different dependents they will be removed
      systemctl disable "$SERVICE.socket"
      systemctl enable "$SERVICE.socket"
    fi
  fi
}

function mask_user_service {
  for SERVICE in "$@"; do
    if systemctl --user cat "$SERVICE" &> /dev/null; then
      for ACTION in stop mask; do
        writeBlue "Running systemctl --user $ACTION $SERVICE..."
        systemctl --user $ACTION "$SERVICE"
        writeBlue "Runned systemctl --user $ACTION $SERVICE."
      done
    fi
  done
}

if [ "$EUID" == '0' ]; then
  if $WSL; then
    create_systemd_service_and_timer wsl-clean-memory
    if ! $RUNNING_IN_CONTAINER; then
      create_systemd_service_and_timer wsl-add-winhost
    fi
  else
    create_systemd_service_and_timer coolercontrol-restart
  fi
else
  # use nix to create systemd services, sockets etc
  # don't call create_systemd_service_and_timer, it will throw an error
  if $WSL; then
    mask_user_service gpg-agent-browser.socket gpg-agent-extra.socket gpg-agent-ssh.socket gpg-agent.socket dirmngr.socket gpg-agent dirmngr ssh-agent
  else
    mask_user_service gcr-ssh-agent.socket gcr-ssh-agent.service
  fi
fi
