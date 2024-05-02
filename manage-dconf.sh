#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run as root"
fi

EXPORT=false
IMPORT=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --import|-i)
    IMPORT=true
    shift
    ;;
    --export|-e)
    EXPORT=true
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
Manages dconf config.

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -u, --update                                       Will download and install/reinstall even if the tools are already installed
      --verbose                                      Show verbose output
  -h, --help                                         This help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS"
fi

DCONF_CONFIGS=(
  "apps/psensor"
  "org/gnome/desktop/datetime"
  "org/gnome/desktop/interface"
  "org/gnome/desktop/input-sources"
  "org/gnome/desktop/peripherals/mouse"
  "org/gnome/desktop/wm/keybindings"
  "org/gnome/shell/extensions/clipboard-history"
  "org/gnome/shell/keybindings"
)
BASE_DATA_DIR="$BASEDIR/config/dconf"
if $EXPORT; then
  if $VERBOSE; then writeGreen "Will export to: $BASE_DATA_DIR"; fi
  for FULL_CONFIG in "${DCONF_CONFIGS[@]}"; do
    CONFIG=`basename "$FULL_CONFIG"`
    CONFIG_DIR=$BASE_DATA_DIR/`dirname "$FULL_CONFIG"`
    if ! [ -d "$CONFIG_DIR" ]; then
      if $VERBOSE; then writeGreen "Creating dir '$CONFIG_DIR'..."; fi
      mkdir -p "$CONFIG_DIR"
    fi
    CONFIG_FILE="$CONFIG_DIR/$CONFIG"
    if $VERBOSE; then writeGreen "Creating config into file '$CONFIG_FILE'..."; fi
    dconf dump "/$FULL_CONFIG/" > "$CONFIG_FILE"
  done
elif $IMPORT; then
  if $VERBOSE; then writeGreen "Will import from: $BASE_DATA_DIR"; fi
  for FULL_CONFIG in "${DCONF_CONFIGS[@]}"; do
    CONFIG=`basename "$FULL_CONFIG"`
    CONFIG_DIR=$BASE_DATA_DIR/`dirname "$FULL_CONFIG"`
    CONFIG_FILE="$CONFIG_DIR/$CONFIG"
    if [ -f "$CONFIG_FILE" ]; then
      if $VERBOSE; then writeGreen "Loading config from '$CONFIG_FILE'..."; fi
      dconf load "/$FULL_CONFIG/" < "$CONFIG_FILE"
    else
      if $VERBOSE; then writeYellow "Config file for '$FULL_CONFIG' does not exist."; fi
    fi
  done
else
  writeGreen "Neither --export nor --import was set. Exiting..."
fi
