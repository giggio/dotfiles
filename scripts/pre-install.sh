#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please run this script as root"
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
Packages for the installation, setup basic tools for dotbot.

Usage:
  $(readlink -f "$0") [flags]

Flags:
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  Update is $UPDATE"
fi

TIME_ZONE_FILE=/usr/share/zoneinfo/America/Sao_Paulo
if { [ -L /etc/localtime ] && [ "$(realpath /etc/localtime)" == "$TIME_ZONE_FILE" ]; } || $RUNNING_IN_CONTAINER; then
  if $VERBOSE; then
    writeBlue "Not updating time zones."
  fi
else
  writeBlue "Setting default time zone to São Paulo."
  ln -fs $TIME_ZONE_FILE /etc/localtime
fi
