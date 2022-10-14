#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" == "0" ]; then
  echo "Please do not run as root"
  exit 2
fi

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
Installs the dotfiles.

Usage:
  `readlink -f $0` [flags]

Flags:
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  echo -e "\e[32mRunning `basename "$0"` $ALL_ARGS\e[0m"
  echo Update is $UPDATE
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTBOT_DIR="$BASEDIR/dotbot"

echo -e "\e[34mUpdating dotbot submodules.\e[0m"
pushd "$DOTBOT_DIR" > /dev/null
git submodule update --init --recursive
popd > /dev/null

echo -e "\e[34mWorking on unpriviledged setup.\e[0m"
"$DOTBOT_DIR/bin/dotbot" -d "${BASEDIR}" -c "$BASEDIR/install.conf.yaml" "${@}"
