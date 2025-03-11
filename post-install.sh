#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run as root"
fi

UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --update | -u)
      UPDATE=true
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
Installs everything after dotbot initial setup.

Usage:
  $(readlink -f "$0") [flags]

Flags:
  -u, --update                                       Will download and install/reinstall even if the tools are already installed
      --verbose                                      Show verbose output
  -h, --help                                         This help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  Update is $UPDATE"
fi

sudo su --login root -c "'$BASEDIR/install-root-pkgs.sh' $*"
sudo su --login root -c "'$BASEDIR/configure-root-env.sh' $*"
if hash systemd-notify 2> /dev/null && systemd-notify --booted; then
  sudo su --login root -c "'$BASEDIR/configure-systemd.sh' $*"
fi
sudo su --login "$USER" -c "'$BASEDIR/install-home-manager.sh' $*"
