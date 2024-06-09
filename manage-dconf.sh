#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run as root"
fi

SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
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
      --verbose                                      Show verbose output
  -h, --help                                         This help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS"
fi

if ! hash dconf2nix 2> /dev/null; then
  die "dconf2nix is not installed."
fi

DCONF_CONFIGS=(
  "apps/psensor"
  "org/gnome/desktop/applications/terminal"
  "org/gnome/desktop/datetime"
  "org/gnome/desktop/interface"
  "org/gnome/desktop/input-sources"
  "org/gnome/desktop/peripherals/mouse"
  "org/gnome/desktop/wm/keybindings"
  "org/gnome/shell/extensions/blur-my-shell"
  "org/gnome/shell/extensions/burn-my-windows"
  "org/gnome/shell/extensions/clipboard-history"
  "org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect"
  "org/gnome/shell/extensions/dash-to-dock"
  "org/gnome/shell/extensions/desktop-cube"
  "org/gnome/shell/extensions/flypie"
  "org/gnome/shell/extensions/freon"
  "org/gnome/shell/extensions/hibernate-status-button"
  "org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect"
  "org/gnome/shell/extensions/wsmatrix"
  "org/gnome/shell/keybindings"
  "org/gnome/settings-daemon/plugins"
  "desktop/ibus/panel/emoji"
)
BASE_DATA_DIR="$BASEDIR/home-manager/dconf"
find "$BASE_DATA_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -r '{}' \;
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
  CONFIG_FILE="$CONFIG_DIR/$CONFIG.nix"
  dconfnixfile+=$'\n    './"`dirname "$FULL_CONFIG"`/$CONFIG.nix"
  if $VERBOSE; then writeGreen "Creating config into file '$CONFIG_FILE'..."; fi
  dconf dump "/$FULL_CONFIG/" | dconf2nix --root "$FULL_CONFIG" > "$CONFIG_FILE"
done
dconfnixfile+='
    ./dconf-config.nix
  ];
}'
if $VERBOSE; then writeGreen "Formatting files..."; fi
pushd "$BASEDIR/home-manager/" > /dev/null
nix fmt
popd > /dev/null
if $VERBOSE; then writeGreen "Creating $BASE_DATA_DIR/dconf.nix file..."; fi
echo "$dconfnixfile" > "$BASE_DATA_DIR/dconf.nix"
