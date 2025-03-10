#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

UPDATE=false
QUICK=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --update | -u)
      UPDATE=true
      shift
      ;;
    --quick)
      QUICK=true
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
Installs the dotfiles.

Usage:
  $(readlink -f "$0") [flags]

Flags:
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
      --quick              Only does the dotbot install, no other setup
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  Update is $UPDATE"
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTBOT_DIR="$BASEDIR/dotbot"

if ! $QUICK; then
  writeBlue "Updating dotbot submodules."
  pushd "$DOTBOT_DIR" > /dev/null
  git submodule update --init --recursive
  popd > /dev/null
fi

writeBlue "Working on unpriviledged setup."
"$DOTBOT_DIR/bin/dotbot" -d "${BASEDIR}" -c "$BASEDIR/install.conf.yaml"
