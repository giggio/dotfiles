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

function install_apt_pkgs () {
  local apt_basic_pkgs_to_install=$1
  local apt_pkgs_to_install=$2
  if [ -v 3 ]; then
    local wsl=" $3"
  else
    local wsl=
  fi
  if $BASIC_SETUP; then
    apt_pkgs_to_install=$apt_basic_pkgs_to_install
  else
    apt_pkgs_to_install=`echo "$apt_basic_pkgs_to_install"$'\n'"$apt_pkgs_to_install" | sort`
  fi
  apt_pkgs_installed=`dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u`
  apt_pkgs_not_installed=`comm -23 <(echo "$apt_pkgs_to_install") <(echo "$apt_pkgs_installed")`
  if [ "$apt_pkgs_not_installed" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Run custom installations with APT$wsl: $apt_pkgs_not_installed
    # shellcheck disable=SC2086
    apt-get install -y $apt_pkgs_not_installed
  elif $VERBOSE; then
    writeBlue "Not installing packages with APT$wsl, they are all already installed."
  fi
}
install_apt_pkgs "`echo "apt-file
gpgconf
libnss3
scdaemon
socat
vim" | sort`" ''

if ! $WSL; then
  # docker
  if ! hash docker 2>/dev/null; then
    curl -fsSL https://get.docker.com | bash
  fi

  apt_basic_pkgs_to_install_not_wsl=
  apt_pkgs_to_install_not_wsl=

  # onedriver
  if ! hash onedriver 2>/dev/null; then
    writeBlue "Install OneDriver."
    echo 'deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_23.10/ /' > /etc/apt/sources.list.d/home:jstaf.list
    curl -fsSL https://download.opensuse.org/repositories/home:jstaf/xUbuntu_23.10/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/home_jstaf.gpg
    apt-get update
    apt_pkgs_to_install_not_wsl+=$'\n'onedriver
  fi
  # flatpak
  if ! hash flatpak 2>/dev/null; then
    apt_pkgs_to_install_not_wsl+=$'\n'flatpak
  fi
  # howdy, from https://github.com/boltgolt/howdy
  if ! hash howdy 2>/dev/null; then
    add-apt-repository -y ppa:boltgolt/howdy
    apt_pkgs_to_install_not_wsl+=$'\n'howdy
    # patch with this code https://github.com/boltgolt/howdy/issues/199#issuecomment-2078573953
  fi

  install_apt_pkgs "$apt_basic_pkgs_to_install_not_wsl" "$apt_pkgs_to_install_not_wsl" '(wsl)'

  function install_platpak_pkgs () {
    local flatpak_basic_pkgs_to_install=$1
    local flatpak_pkgs_to_install=$2
    if $BASIC_SETUP; then
      flatpak_pkgs_to_install=$flatpak_basic_pkgs_to_install
    else
      flatpak_pkgs_to_install=`echo "$flatpak_basic_pkgs_to_install"$'\n'"$flatpak_pkgs_to_install" | sort`
    fi
    flatpak_pkgs_installed=`flatpak list --app --columns=application --system | tail -n+1 | sort -u`
    flatpak_pkgs_not_installed=`comm -23 <(echo "$flatpak_pkgs_to_install") <(echo "$flatpak_pkgs_installed")`
    if [ "$flatpak_pkgs_not_installed" != "" ]; then
      # shellcheck disable=SC2086
      writeBlue Run custom installations with Flatpak: $flatpak_pkgs_not_installed
      # shellcheck disable=SC2086
      apt-get install -y $flatpak_pkgs_not_installed
    elif $VERBOSE; then
      writeBlue "Not installing packages with Flatpak, they are all already installed."
    fi
  }
  install_platpak_pkgs '' "`echo "com.valvesoftware.Steam
net.davidotek.pupgui2" | sort`" ''

fi

# nix
if ! [ -f /etc/bash.bashrc.backup-before-nix ]; then
  writeBlue "Install Nix."
  sh <(curl -L https://nixos.org/nix/install) --daemon --yes
elif $VERBOSE; then
  writeBlue "Not installing Nix, it is already installed."
fi

# upgrade
if $UPDATE; then
  writeBlue "Upgrade with APT."
  apt-get upgrade -y
  flatpak update -y
else
  if $VERBOSE; then
    writeBlue "Not updating with APT."
  fi
fi

clean
