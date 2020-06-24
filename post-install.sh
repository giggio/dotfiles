#!/usr/bin/env bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALL_ARGS=$@
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
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

if $SHOW_HELP; then
  cat <<EOF
Installs everything after dotbot initial setup.

Usage:
  `readlink -f $0` [flags]

Flags:
  -u, --update                                       Will download and install/reinstall even if the tools are already installed
      --verbose                                      Show verbose output
  -h, --help                                         This help
EOF
  exit 0
fi

if $VERBOSE; then
  echo -e "\e[32mRunning `basename "$0"` $ALL_ARGS\e[0m"
  echo Update is $UPDATE
fi

sudo -E $BASEDIR/install-root-pkgs.sh $ALL_ARGS
$BASEDIR/install-user-pkgs.sh $ALL_ARGS
$BASEDIR/install-platform-tools.sh $ALL_ARGS
sudo -E $BASEDIR/configure-root-env.sh $ALL_ARGS
$BASEDIR/configure-user-env.sh $ALL_ARGS

