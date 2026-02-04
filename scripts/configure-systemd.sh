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

function mask_service {
  for SERVICE in "$@"; do
    if systemctl cat "$SERVICE" &> /dev/null; then
      for ACTION in stop mask; do
        writeBlue "Running systemctl $ACTION $SERVICE..."
        systemctl --user $ACTION "$SERVICE"
        writeBlue "Runned systemctl $ACTION $SERVICE."
      done
    fi
  done
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

function create_systemd_script_hooks {
  local NEEDS_RELOAD=false
  if [ "$EUID" != '0' ]; then
    die "Use nix to create systemd user services, sockets etc."
  fi
  local SOURCE_DIR="$BASEDIR"/systemd/hooks
  local SYSTEMD_DIR=/lib/systemd/
  for HOOK_DIR in "$SOURCE_DIR"/*; do
    if ! [ -d "$HOOK_DIR" ]; then
      continue
    fi
    local HOOK_NAME
    HOOK_NAME=$(basename "$HOOK_DIR")
    local DESTINATION_HOOK_DIR=$SYSTEMD_DIR/$HOOK_NAME
    if ! [ -d "$DESTINATION_HOOK_DIR" ]; then
      if $VERBOSE; then
        writeBlue "Creating directory $DESTINATION_HOOK_DIR."
      fi
      mkdir -p "$DESTINATION_HOOK_DIR"
      NEEDS_RELOAD=true
    fi
    for HOOK_FILE in "$HOOK_DIR"/*; do
      if [ -f "$HOOK_FILE" ]; then
        local DESTINATION_HOOK_FILE
        DESTINATION_HOOK_FILE=$DESTINATION_HOOK_DIR/$(basename "$HOOK_FILE")
        if ! [ -f "$DESTINATION_HOOK_FILE" ] || ! cmp --quiet "$HOOK_FILE" "$DESTINATION_HOOK_FILE"; then
          if $VERBOSE; then
            writeBlue "Copying $HOOK_FILE to $DESTINATION_HOOK_FILE."
          fi
          cp "$HOOK_FILE" "$DESTINATION_HOOK_FILE"
          NEEDS_RELOAD=true
        elif $VERBOSE; then
          writeBlue "No need to copy $HOOK_FILE to $DESTINATION_HOOK_FILE, it already exists and is the same."
        fi
      fi
    done
  done
  if $NEEDS_RELOAD; then
    writeBlue "Reloading systemd."
    systemctl daemon-reload
  fi
}

# use nix to create systemd services, sockets etc
if [ "$EUID" == '0' ]; then
  create_systemd_script_hooks
else
  if $WSL; then
    mask_user_service gpg-agent-browser.socket gpg-agent-extra.socket gpg-agent-ssh.socket gpg-agent.socket dirmngr.socket gpg-agent dirmngr ssh-agent
  else
    mask_user_service gcr-ssh-agent.socket gcr-ssh-agent.service
  fi
fi
