#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please run this script as root"
fi

BASIC_SETUP=false
CURL_GH_HEADERS=()
UPDATE=false
CLEAN=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --basic|-b)
    BASIC_SETUP=true
    shift
    ;;
    --gh)
    CURL_GH_HEADERS=(-H "Authorization: token $2")
    shift 2
    ;;
    --clean|-c)
    CLEAN=true
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
Installs root packages.

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
      --gh <user:pw>       GitHub username and password
  -c, --clean              Will clean installed packages.
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE
  Basic setup is $BASIC_SETUP
  Clean is $CLEAN"
fi

clean() {
  if $CLEAN; then
    writeBlue "Cleanning up packages."
    apt-get autoremove -y
  elif $VERBOSE; then
    writeBlue "Not auto removing with APT."
  fi
}

writeBlue "Update APT metadata."
apt-get update

APT_BASIC_PKGS_TO_INSTALL=`echo "apt-file
gpgconf
libnss3
scdaemon
socat
tmux
vim" | sort`
APT_PKGS_TO_INSTALL=
if $BASIC_SETUP; then
  APT_PKGS_TO_INSTALL=$APT_BASIC_PKGS_TO_INSTALL
else
  APT_PKGS_TO_INSTALL=`echo "$APT_BASIC_PKGS_TO_INSTALL"$'\n'"$APT_PKGS_TO_INSTALL" | sort`
fi
APT_PKGS_INSTALLED=`dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u`
APT_PKGS_NOT_INSTALLED=`comm -23 <(echo "$APT_PKGS_TO_INSTALL") <(echo "$APT_PKGS_INSTALLED")`
if [ "$APT_PKGS_NOT_INSTALLED" != "" ]; then
  # shellcheck disable=SC2086
  writeBlue Run custom installations with APT: $APT_PKGS_NOT_INSTALLED
  # shellcheck disable=SC2086
  apt-get install -y $APT_PKGS_NOT_INSTALLED
elif $VERBOSE; then
  writeBlue "Not installing packages with APT, they are all already installed."
fi

if ! $WSL; then
  # docker
  if ! hash docker 2>/dev/null; then
    curl -fsSL https://get.docker.com | bash
  fi

  APT_PKGS_TO_INSTALL_NOT_WSL=""
  APT_PKGS_NOT_INSTALLED_NOT_WSL=`comm -23 <(echo "$APT_PKGS_TO_INSTALL_NOT_WSL") <(echo "$APT_PKGS_INSTALLED")`
  if [ "$APT_PKGS_NOT_INSTALLED_NOT_WSL" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Run custom installations with APT - not WSL: $APT_PKGS_NOT_INSTALLED_NOT_WSL
    # shellcheck disable=SC2086
    apt-get install -y $APT_PKGS_NOT_INSTALLED_NOT_WSL
  elif $VERBOSE; then
    writeBlue "Not installing packages with APT (not WSL), they are all already installed."
  fi
fi

# upgrade
if $UPDATE; then
  writeBlue "Upgrade with APT."
  apt-get upgrade -y
else
  if $VERBOSE; then
    writeBlue "Not updating with APT."
  fi
fi

if ! hash nix-instantiate 2>/dev/null || ! nix-instantiate '<nixpkgs>' -A hello &> /dev/null; then
  writeBlue "Install Nix."
  sh <(curl -L https://nixos.org/nix/install) --daemon --yes
fi

# exit if basic setup is requested
# up until this point we had the necessary packages
if $BASIC_SETUP; then
  clean
  exit
fi

if ! $WSL; then
  # onedriver
  if ! hash onedriver 2>/dev/null; then
    writeBlue "Install OneDriver."
    echo 'deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_23.10/ /' > /etc/apt/sources.list.d/home:jstaf.list
    curl -fsSL https://download.opensuse.org/repositories/home:jstaf/xUbuntu_23.10/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/home_jstaf.gpg
    apt-get update
    apt-get install -y onedriver
  fi
fi

clean
