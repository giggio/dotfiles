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
Packages installer.

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

if ! [ -f /etc/sudoers.d/10-cron ]; then
  writeBlue "Allow cron to start without su."
  echo "#allow cron to start without su
%sudo ALL=NOPASSWD: /etc/init.d/cron start" | tee /etc/sudoers.d/10-cron
  chmod 440 /etc/sudoers.d/10-cron
else
  if $VERBOSE; then
    writeBlue "Not generating sudoers file for Cron, it is already there."
  fi
fi

function setAlternative() {
  NAME=$1
  EXEC_PATH=`which "$2"`
  if [ "`update-alternatives --display "$NAME" | sed -n 's/.*link currently points to \(.*\)$/\1/p'`" != "$EXEC_PATH" ]; then
    update-alternatives --set "$NAME" "$EXEC_PATH"
  else
    if $VERBOSE; then
      writeBlue "Not updating alternative to $NAME, it is already set."
    fi
  fi
}

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
