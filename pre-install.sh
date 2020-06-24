#!/usr/bin/env bash

set -euo pipefail

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
Packages for the installation, setup basic tools for dotbot.

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

if ! hash python2.7 2>/dev/null || ! hash python3.8 2>/dev/null; then
  echo -e "\e[34mInstalling Python 2 and 3.\e[0m"
  sudo apt-get update
  sudo apt-get install -y python2.7 python3.8
fi
if ! update-alternatives --display python &>/dev/null; then
  echo -e "\e[34mSetting the default Python to version 3.\e[0m"
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 2
  sudo update-alternatives  --set python /usr/bin/python3.8
else
  if $VERBOSE; then
    echo "Not Adding Python alternatives, they are already present."
  fi
fi

if $UPDATE; then
  echo -e "\e[34mUpgrading all packages.\e[0m"
  sudo apt-get upgrade -y
else
  if $VERBOSE; then
    echo "Not updating with APT."
  fi
fi

if ! [ -L /etc/localtime ] || [ `realpath /etc/localtime` != "/usr/share/zoneinfo/America/Sao_Paulo" ]; then
  echo -e "\e[34mSetting default time zone to São Paulo.\e[0m"
  sudo ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
else
  if $VERBOSE; then
    echo "Not updating time zones."
  fi
fi
