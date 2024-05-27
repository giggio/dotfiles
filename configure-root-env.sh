#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please run this script as root"
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
Configures root environment.

Usage:
  `readlink -f "$0"` [flags]

Flags:
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS"
fi

if ! [[ `locale -a` =~ en_US\.utf8 ]]; then
  writeBlue "Generate location."
  locale-gen en_US.UTF-8
else
  if $VERBOSE; then
    writeBlue "Not generating location, it is already generated."
  fi
fi

if $WSL && ! $RUNNING_IN_CONTAINER; then
  if hash wslview 2>/dev/null; then
    setAlternative x-www-browser wslview
  else
    if $VERBOSE; then
      writeBlue "Not setting browser to wslview, wslview is not available."
    fi
  fi
fi

setAlternative editor /usr/bin/vim.basic

if $WSL; then
  "$BASEDIR"/configure-root-env-wsl.sh "$@"
elif $ANDROID; then
  "$BASEDIR"/configure-root-env-android.sh "$@"
else
  # non-WSL, non-Android
  if [ -v SUDO_USER ]; then
    groups_to_add=(docker i2c)
    for group in "${groups_to_add[@]}"; do
      if ! getent group "$group" &> /dev/null; then
        writeBlue "Group $group does not exist."
      else
        if getent group "$group" | grep -qw "$SUDO_USER"; then
          if $VERBOSE; then
            writeBlue "$SUDO_USER is already in $group group."
          fi
        else
          writeBlue "Adding $SUDO_USER to $group group."
          usermod "$SUDO_USER" -aG "$group"
        fi
      fi
    done

    # Move openrgb udev rules file to udev rules directory
    openrgb_bin=`su - "$SUDO_USER" -c "which openrgb || true"`
    if [ -n "$openrgb_bin" ]; then
      openrgb_rules="$(realpath "$(dirname "$(readlink -f "$openrgb_bin")")"/../lib/udev/rules.d/60-openrgb.rules)"
      if [ -f "$openrgb_rules" ]; then
        destination_udev_rules=/usr/lib/udev/rules.d/60-openrgb.rules
        if [ "`readlink -f /usr/lib/udev/rules.d/60-openrgb.rules`" = "$openrgb_rules" ]; then
          if $VERBOSE; then
            writeBlue "OpenRGB udev rules are already linked."
          fi
        else
          writeBlue "Linking OpenRGB udev rules from $openrgb_rules to $destination_udev_rules."
          ln -fs "$openrgb_rules" $destination_udev_rules
          writeBlue "Reloading udev rules for openrgb."
          udevadm control --reload-rules
          udevadm trigger
        fi
      else
        writeBlue "OpenRGB udev rules do not exist."
      fi
    else
      writeBlue "OpenRGB is not installed."
    fi
  fi
fi
