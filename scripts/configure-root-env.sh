#!/usr/bin/env bash

SCRIPTSDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/_common-setup.sh
source "$SCRIPTSDIR"/_common-setup.sh

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

if $WSL; then
  "$SCRIPTSDIR"/configure-root-env-wsl.sh "$@"
elif $ANDROID; then
  "$SCRIPTSDIR"/configure-root-env-android.sh "$@"
else
  # non-WSL, non-Android

  # patch /etc/pam.d/common-session-noninteractive, see: https://askubuntu.com/a/1052885/832580
  # this is to allow encrypted home to unmount on logout
  if [ -f /etc/pam.d/common-session-noninteractive ]; then
    if grep pam_ecryptfs.so /etc/pam.d/common-session-noninteractive -q; then
      writeBlue "Patching /etc/pam.d/common-session-noninteractive."
      verbose_flag=
      if $VERBOSE; then verbose_flag="--verbose"; fi
      patch --ignore-whitespace $verbose_flag -u /etc/pam.d/common-session-noninteractive -i "$SCRIPTSDIR"/patches/common-session-noninteractive.patch --merge
    else
      if $VERBOSE; then
        writeYellow "PAM configuration file /etc/pam.d/common-session-noninteractive does not contain pam_ecryptfs.so."
      fi
    fi
  else
    writeYellow "PAM configuration file /etc/pam.d/common-session-noninteractive does not exist."
  fi
fi
