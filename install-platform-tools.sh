#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

BASIC_SETUP=false
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --basic|-b)
    BASIC_SETUP=true
    shift
    ;;
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
Install platform tools (Krew tools etc).

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE
  Basic setup is $BASIC_SETUP"
fi

if $BASIC_SETUP; then
  exit
fi


# krew tools
if hash krew 2>/dev/null; then
  krew update
  KREW_PLUGINS_INSTALLED=`krew list | tail -n+1 | awk '{print $1}' | sort -u`
  KREW_PLUGINS_TO_INSTALL=`echo "get-all
resource-capacity
sniff
tail" | sort`
  KREW_PLUGINS_NOT_INSTALLED=`comm -23 <(echo "$KREW_PLUGINS_TO_INSTALL") <(echo "$KREW_PLUGINS_INSTALLED")`
  if [ "$KREW_PLUGINS_NOT_INSTALLED" != "" ]; then
    writeBlue "Installing Krew plugins: $KREW_PLUGINS_NOT_INSTALLED"
    # shellcheck disable=SC2086
    krew install $KREW_PLUGINS_NOT_INSTALLED
  elif $VERBOSE; then
    writeBlue "Not installing krew plugins, they are already installed."
  fi
  if $UPDATE; then
    writeBlue "Updating Krew plugins."
    krew upgrade
  fi
else
  writeBlue "Krew not available, skipping..."
fi
