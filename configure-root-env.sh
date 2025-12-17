#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please run this script as root"
fi

SHOW_HELP=false
VERBOSE=false
BASIC_SETUP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --basic | -b)
      BASIC_SETUP=true
      shift
      ;;
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
Configures root environment.

Usage:
  $(readlink -f "$0") [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  Basic setup is $BASIC_SETUP"
fi

if $VERBOSE; then
  writeBlue "Setting basic setup to $BASIC_SETUP in /etc/profile.d/01-basic-setup.sh."
fi
echo "export BASIC_SETUP=$BASIC_SETUP" > /etc/profile.d/01-basic-setup.sh

if ! [[ $(locale -a) =~ en_US\.utf8 ]]; then
  writeBlue "Generate location."
  locale-gen en_US.UTF-8
else
  if $VERBOSE; then
    writeBlue "Not generating location, it is already generated."
  fi
fi

if ! [ -f /etc/profile.d/xdg_dirs_extra.sh ]; then
  if $VERBOSE; then
    writeBlue "Copying xdg_dirs_extra.sh to /etc/profile.d/."
  fi
  cp "$BASEDIR"/setup/xdg_dirs_extra.sh /etc/profile.d/
elif $VERBOSE; then
  writeBlue "Not copying xdg_dirs_extra.sh, it already exists."
fi

if $WSL && ! $RUNNING_IN_CONTAINER; then
  if hash wslview 2> /dev/null; then
    setAlternative x-www-browser wslview
  else
    if $VERBOSE; then
      writeBlue "Not setting browser to wslview, wslview is not available."
    fi
  fi
fi

setAlternative editor /usr/bin/vim.basic

# todo: find a way to create apparmor profiles for nix packages
# until then, make apparmor allow unprivileged user namespaces
# This became a problem since Ubuntu 24.04
# See: https://discourse.ubuntu.com/t/ubuntu-24-04-lts-noble-numbat-release-notes/39890#unprivileged-user-namespace-restrictions-15
if hash aa-status 2> /dev/null && aa-status &> /dev/null; then
  if [ -f /etc/sysctl.d/60-apparmor-namespace.conf ]; then
    if $VERBOSE; then
      writeBlue "Apparmor is already set to allow unprivileged user namespaces."
    fi
  else
    if $VERBOSE; then
      writeBlue "Setting Apparmor to allow unprivileged user namespaces."
    fi
    echo 'kernel.apparmor_restrict_unprivileged_userns=0' > /etc/sysctl.d/60-apparmor-namespace.conf
  fi
else
  writeBlue "Apparmor is not installed or is not running."
fi

if $WSL; then
  "$BASEDIR"/configure-root-env-wsl.sh "$@"
elif $ANDROID; then
  "$BASEDIR"/configure-root-env-android.sh "$@"
else
  # non-WSL, non-Android

  # patch /etc/pam.d/common-session-noninteractive, see: https://askubuntu.com/a/1052885/832580
  # this is to allow encrypted home to unmount on logout
  if [ -f /etc/pam.d/common-session-noninteractive ]; then
    if grep pam_ecryptfs.so /etc/pam.d/common-session-noninteractive -q; then
      writeBlue "Patching /etc/pam.d/common-session-noninteractive."
      verbose_flag=
      if $VERBOSE; then verbose_flag="--verbose"; fi
      patch --ignore-whitespace $verbose_flag -u /etc/pam.d/common-session-noninteractive -i "$BASEDIR"/patches/common-session-noninteractive.patch --merge
    else
      if $VERBOSE; then
        writeYellow "PAM configuration file /etc/pam.d/common-session-noninteractive does not contain pam_ecryptfs.so."
      fi
    fi
  else
    writeYellow "PAM configuration file /etc/pam.d/common-session-noninteractive does not exist."
  fi

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
    openrgb_bin=$(su - "$SUDO_USER" -c "which openrgb || true")
    if [ -n "$openrgb_bin" ]; then
      openrgb_rules="$(realpath "$(dirname "$(readlink -f "$openrgb_bin")")"/../lib/udev/rules.d/60-openrgb.rules)"
      if [ -f "$openrgb_rules" ]; then
        destination_udev_rules=/usr/lib/udev/rules.d/60-openrgb.rules
        if [ "$(readlink -f /usr/lib/udev/rules.d/60-openrgb.rules)" = "$openrgb_rules" ]; then
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

    # liquidctl configuration
    # todo: keep this here until liquidctl is updated to run with my water cooler
    if ! [ -f /usr/lib/udev/rules.d/71-liquidctl.rules ]; then
      writeBlue "Installing liquidctl udev rules."
      curl -fsSL --output /usr/lib/udev/rules.d/71-liquidctl.rules https://raw.githubusercontent.com/liquidctl/liquidctl/refs/heads/main/extra/linux/71-liquidctl.rules
      udevadm control --reload
      udevadm trigger
    else
      if $VERBOSE; then
        writeBlue "liquidctl udev rules already exist."
      fi
    fi
    if hash aa-status 2> /dev/null && aa-status --enabled; then
      if ! [ -f /etc/apparmor.d/usr.local.bin.liquidctl ]; then
        writeBlue "Copying apparmor profile for liquidctl."
        cp "$BASEDIR"/setup/apparmor-liquidctl.txt /etc/apparmor.d/usr.local.bin.liquidctl
        apparmor_parser -r /etc/apparmor.d/usr.local.bin.liquidctl
      else
        if $VERBOSE; then
          writeBlue "Apparmor profile for liquidctl already exists."
        fi
      fi
    fi
  fi
fi

if hash sensors 2> /dev/null; then
  if sensors -u 2> /dev/null | grep -q asusec-isa; then
    if ! [ -f /etc/sensors.d/disabling ]; then
      cat << EOF > /etc/sensors.d/disabling
chip "asusec-*"
  ignore temp1
  ignore temp2
  ignore temp3
  ignore temp5
  ignore temp6
EOF
    else
      if $VERBOSE; then
        writeBlue "asusec-isa is already disabled."
      fi
    fi
  else
    if $VERBOSE; then
      writeBlue "asusec-isa is not available."
    fi
  fi
else
  writeBlue "sensors is not installed."
fi
