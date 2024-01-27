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
    --update|-u)
    UPDATE=true
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
Packages for the installation, setup basic tools for dotbot.

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE"
fi

if ! hash python2.7 2>/dev/null || ! hash python3 2>/dev/null; then
  writeBlue "Installing Python 2 and 3."
  apt-get update
  apt-get install -y python2.7 python3 python3-pip
fi
installAlternative python /usr/bin/python /usr/bin/python2.7
installAlternative python /usr/bin/python /usr/bin/python3

# setup pysemver
if ! hash pysemver 2>/dev/null; then
  PIP_PKGS_INSTALLED=`pip3 list --format columns | tail -n +3 | awk '{print $1}' | sort -u`
  PIP_PKGS_TO_INSTALL="semver"
  PIP_PKGS_NOT_INSTALLED=`comm -23 <(echo "$PIP_PKGS_TO_INSTALL") <(echo "$PIP_PKGS_INSTALLED")`
  if [ "$PIP_PKGS_NOT_INSTALLED" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Install packages $PIP_PKGS_NOT_INSTALLED with Pip for root.
    # shellcheck disable=SC2086
    pip3 install $PIP_PKGS_NOT_INSTALLED
  elif $VERBOSE; then
    writeBlue "Not installing Pip packages for root, they are already installed."
  fi
fi

if { [ -L /etc/localtime ] && [ "`realpath /etc/localtime`" == "/usr/share/zoneinfo/America/Sao_Paulo" ] ; } || $RUNNING_IN_CONTAINER; then
  if $VERBOSE; then
    writeBlue "Not updating time zones."
  fi
else
  writeBlue "Setting default time zone to São Paulo."
  ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
fi
