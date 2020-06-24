#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" == "0" ]; then
  echo "Please do not run this script as root"
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
Installs user packages.

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

# deno
if ! hash deno 2>/dev/null && ! [ -f $HOME/.deno/bin/deno ] || $UPDATE; then
  echo -e "\e[34mInstall Deno.\e[0m"
  curl -fsSL https://deno.land/x/install/install.sh | sh
else
  if $VERBOSE; then
    echo "Not installing Deno, it is already installed."
  fi
fi

# rbenv
if ! [ -f $BASEDIR/tools/rbenv/shims/ruby ] || $UPDATE; then
  echo -e "\e[34mInstall ruby-build and install Ruby with rbenv.\e[0m"
  git clone https://github.com/rbenv/ruby-build.git $BASEDIR/tools/rbenv/plugins/ruby-build
  $HOME/.rbenv/bin/rbenv install 2.7.1
  $HOME/.rbenv/bin/rbenv global 2.7.1
else
  if $VERBOSE; then
    echo "Not installing Rbenv and generating Ruby, it is already installed."
  fi
fi
