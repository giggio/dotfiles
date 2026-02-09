#!/usr/bin/env bash

SCRIPTSDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/_common-setup.sh
source "$SCRIPTSDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

BASIC_SETUP=false
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --basic | -b)
      BASIC_SETUP=true
      shift
      ;;
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
Installs user packages.

Usage:
  $(readlink -f "$0") [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  Update is $UPDATE
  Basic setup is $BASIC_SETUP"
fi

download_nixpkgs_cache_index() {
  local filename
  filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr '[:upper:]' '[:lower:]')"
  mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
  wget -q -N "https://github.com/Mic92/nix-index-database/releases/latest/download/$filename"
  ln -f "$filename" files
}
hm_switch() {
  local verbose_flag=
  if $VERBOSE; then verbose_flag="--verbose"; fi
  "$SCRIPTSDIR"/home-manager/bin/hm switch --show-trace $verbose_flag "$@"
}
setup_nix_channels() {
  writeBlue "Setting up Nix channels."
  local channel_added=false
  if nix-channel --list | grep -q nixpkgs; then
    if $VERBOSE; then
      writeBlue "Nix channel nixpkgs already exists."
    fi
  else
    nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
    channel_added=true
  fi
  if nix-channel --list | grep -q home-manager; then
    if $VERBOSE; then
      writeBlue "Nix channel home-manager already exists."
    fi
  else
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    channel_added=true
  fi
  if $channel_added; then
    if $VERBOSE; then
      writeBlue "Update Nix channels."
    fi
    nix-channel --update
  else
    writeBlue "No nix channels to update, they were already added."
  fi
}

install_system_manager() {
  if ! hash system-manager 2> /dev/null; then
    writeBlue "Install Nix system-manager."
    sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.backup
    "$SCRIPTSDIR"/../system-manager/bin/sm switch --first-run
  elif $UPDATE; then
    writeBlue "Update Nix system-manager."
    rm -f "$SCRIPTSDIR"/../system-manager/flake.lock
    hm_switch --refresh
    download_nixpkgs_cache_index
  else
    writeBlue "Not installing Nix system-manager, it is already installed."
  fi
}

install_home_manager() {
  if ! hash home-manager 2> /dev/null; then
    setup_nix_channels
    writeBlue "Install Nix home-manager."
    nix run home-manager/master -- init --show-trace --flake "$SCRIPTSDIR"/../home-manager?submodules=1
    hm_switch
    download_nixpkgs_cache_index
  elif $UPDATE; then
    writeBlue "Update Nix home-manager."
    nix-channel --update
    rm -f "$SCRIPTSDIR"/../home-manager/flake.lock
    hm_switch --refresh
    download_nixpkgs_cache_index
  elif $VERBOSE; then
    writeBlue "Not installing Nix home-manager, it is already installed."
  fi
}

if (return 0 2> /dev/null); then
  # if sourced, remove the set -euo pipefail
  set +euo pipefail
else
  # if not sourced, run the installation
  install_system_manager
  install_home_manager
fi
