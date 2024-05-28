#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run as root"
fi

EXPORT=false
IMPORT=false
NIX=false
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
    --nix|-n)
    NIX=true
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
  -i, --import                                       Imports into dconf config from files
  -e, --export                                       Exports from from files into dconf config
  -n, --nix                                          Use Nix format when exporting
      --verbose                                      Show verbose output
  -h, --help                                         This help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Import is $IMPORT
  Export is $EXPORT
  Nix is $NIX"
fi

if $NIX && ! $EXPORT; then
  die "Nix can only be used with export."
fi

if $NIX && ! hash dconf2nix 2> /dev/null; then
  die "dconf2nix is not installed."
fi

DCONF_CONFIGS=(
  "apps/psensor"
  "org/gnome/desktop/datetime"
  "org/gnome/desktop/interface"
  "org/gnome/desktop/input-sources"
  "org/gnome/desktop/peripherals/mouse"
  "org/gnome/desktop/wm/keybindings"
  "org/gnome/shell/extensions/clipboard-history"
  "org/gnome/shell/extensions/dash-to-dock"
  "org/gnome/shell/keybindings"
  "org/gnome/settings-daemon/plugins"
  "desktop/ibus/panel/emoji"
)
if $NIX; then
  BASE_DATA_DIR="$BASEDIR/config/home-manager/dconf"
else
  BASE_DATA_DIR="$BASEDIR/config/dconf"
fi
if $EXPORT; then
  if $VERBOSE; then writeGreen "Will export to: $BASE_DATA_DIR"; fi
  dconfnixfile='{
  imports = ['
  for FULL_CONFIG in "${DCONF_CONFIGS[@]}"; do
    CONFIG=`basename "$FULL_CONFIG"`
    CONFIG_DIR=$BASE_DATA_DIR/`dirname "$FULL_CONFIG"`
    if ! [ -d "$CONFIG_DIR" ]; then
      if $VERBOSE; then writeGreen "Creating dir '$CONFIG_DIR'..."; fi
      mkdir -p "$CONFIG_DIR"
    fi
    CONFIG_FILE="$CONFIG_DIR/$CONFIG"
    if $NIX; then
      CONFIG_FILE="$CONFIG_FILE.nix"
    fi
    dconfnixfile+=$'\n    './"`dirname "$FULL_CONFIG"`/$CONFIG.nix"
    if $VERBOSE; then writeGreen "Creating config into file '$CONFIG_FILE'..."; fi
    if $NIX; then
      dconf dump "/$FULL_CONFIG/" | dconf2nix --emoji --root "$FULL_CONFIG" > "$CONFIG_FILE"
    else
      dconf dump "/$FULL_CONFIG/" > "$CONFIG_FILE"
    fi
  done
  dconfnixfile+='
  ];
}'
  if $VERBOSE; then writeGreen "Creating $BASE_DATA_DIR/dconf.nix file..."; fi
  echo "$dconfnixfile" > "$BASE_DATA_DIR/dconf.nix"
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
