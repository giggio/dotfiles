#!/usr/bin/env bash

SCRIPTSDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/_common-setup.sh
source "$SCRIPTSDIR"/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please run this script as root"
fi

BASIC_SETUP=false
UPDATE=false
SERVER_SETUP=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --server | -s)
      SERVER_SETUP=true
      shift
      ;;
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
Installs root packages.

Usage:
  $(readlink -f "$0") [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
      --gh <user:pw>       GitHub username and password
  -s, --server             Server installation, assumes basic, removes all desktop tools and some client tools.
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $ARM && ! $ANDROID; then
  SERVER_SETUP=true
fi

if $SERVER_SETUP; then
  BASIC_SETUP=true
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS
  Update is $UPDATE
  WSL is $WSL
  Basic setup is $BASIC_SETUP
  Server setup is $SERVER_SETUP"
fi

if [[ $(($(date +%s) - $(stat --format=%X /var/cache/apt/pkgcache.bin))) -gt $((12 * 60 * 60)) ]]; then
  writeBlue "Update APT metadata."
  apt-get update
else
  if $VERBOSE; then
    writeBlue "Not updating APT metadata, it was updated less than 12 hours ago."
  fi
fi

function install_apt_pkgs() {
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
    apt_pkgs_to_install=$(echo "$apt_basic_pkgs_to_install"$'\n'"$apt_pkgs_to_install" | sort)
  fi
  apt_pkgs_installed=$(dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u)
  apt_pkgs_not_installed=$(comm -23 <(echo "$apt_pkgs_to_install") <(echo "$apt_pkgs_installed"))
  if [ "$apt_pkgs_not_installed" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Run custom installations with APT$wsl: $apt_pkgs_not_installed
    # shellcheck disable=SC2086
    apt-get install -y $apt_pkgs_not_installed
  elif $VERBOSE; then
    writeBlue "Not installing packages with APT$wsl, they are all already installed."
  fi
}
install_apt_pkgs "$(echo "apt-file
curl
gpg
gpgconf
libnss3
locales
pipx
pkg-config
scdaemon
socat
software-properties-common
vim
wget" | sort)" ''

if ! $WSL; then
  # docker
  if ! hash docker 2> /dev/null; then
    writeBlue "Install Docker."
    curl -fsSL https://get.docker.com | bash
  fi

  apt_basic_pkgs_to_install_not_wsl=$'\n'kitty-terminfo
  apt_pkgs_to_install_not_wsl=$'\n'systemd-timesyncd

  if ! $SERVER_SETUP; then
    # flatpak
    if ! hash flatpak 2> /dev/null; then
      apt_pkgs_to_install_not_wsl+=$'\n'flatpak
    fi
    # howdy, from https://github.com/boltgolt/howdy
    if ! hash howdy 2> /dev/null; then
      if ! $RUNNING_IN_CONTAINER; then
        add-apt-repository -y ppa:boltgolt/howdy
        apt_pkgs_to_install_not_wsl+=$'\n'howdy
      fi
    fi

    install_apt_pkgs "$apt_basic_pkgs_to_install_not_wsl" "$apt_pkgs_to_install_not_wsl" '(wsl)'

    if ! $RUNNING_IN_CONTAINER; then
      # patch /lib/security/howdy/pam.py to allow howdy to work with encrypted home and not try to detect face when home is encrypted
      # See https://github.com/boltgolt/howdy/issues/199#issuecomment-2078573953
      verbose_flag=
      if $VERBOSE; then verbose_flag="--verbose"; fi
      if ! grep 'Abort if user is not root' /lib/security/howdy/pam.py -q; then
        patch --ignore-whitespace $verbose_flag -u /lib/security/howdy/pam.py -i "$SCRIPTSDIR"/patches/howdy-pam.py.patch
        patch --ignore-whitespace $verbose_flag -u /usr/lib/security/howdy/config.ini -i "$SCRIPTSDIR"/patches/howdy-config.patch
      fi
    fi

    function install_flatpak_pkgs() {
      local flatpak_basic_pkgs_to_install=$1
      local flatpak_pkgs_to_install=$2
      local flatpak_pkgs_to_install_if_not_container=''
      if ! $RUNNING_IN_CONTAINER; then
        flatpak_pkgs_to_install_if_not_container=$3
      fi
      if ! flatpak remotes --columns=name | grep -q flathub; then
        writeBlue "Install Flatpak remote Flathub."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      else
        if $VERBOSE; then
          writeBlue "Not adding Flatpak remote Flathub, it is already added."
        fi
      fi
      if $BASIC_SETUP; then
        flatpak_pkgs_to_install=$flatpak_basic_pkgs_to_install
      else
        flatpak_pkgs_to_install=$(echo "$flatpak_basic_pkgs_to_install"$'\n'"$flatpak_pkgs_to_install"$'\n'"$flatpak_pkgs_to_install_if_not_container" | sort)
      fi
      local flatpak_pkgs_installed
      flatpak_pkgs_installed=$(flatpak list --app --columns=application --system | tail -n+1 | sort -u)
      local flatpak_pkgs_not_installed
      flatpak_pkgs_not_installed=$(comm -23 <(echo "$flatpak_pkgs_to_install") <(echo "$flatpak_pkgs_installed"))
      if [ "$flatpak_pkgs_not_installed" != "" ]; then
        # shellcheck disable=SC2086
        writeBlue Run custom installations with Flatpak: $flatpak_pkgs_not_installed
        # shellcheck disable=SC2086
        flatpak install -y $flatpak_pkgs_not_installed
      elif $VERBOSE; then
        writeBlue "Not installing packages with Flatpak, they are all already installed."
      fi
    }
    install_flatpak_pkgs '' "net.davidotek.pupgui2" "com.microsoft.AzureStorageExplorer"

    function install_snap_pkgs() {
      local snap_basic_pkgs_to_install=$1
      local snap_pkgs_to_install=$2
      if $BASIC_SETUP; then
        snap_pkgs_to_install=$snap_basic_pkgs_to_install
      else
        snap_pkgs_to_install=$(echo "$snap_basic_pkgs_to_install"$'\n'"$snap_pkgs_to_install" | sort)
      fi
      if ! hash snap 2> /dev/null; then
        writeBlue "Install Snap."
        apt-get install -y snapd
      fi
      snap_pkgs_installed=$(snap list | awk '{ print $1 }' | tail -n+2 | sort -u)
      snap_pkgs_not_installed=$(comm -23 <(echo "$snap_pkgs_to_install") <(echo "$snap_pkgs_installed"))
      if [ "$snap_pkgs_not_installed" != "" ]; then
        # shellcheck disable=SC2086
        writeBlue Run custom installations with Snap: $snap_pkgs_not_installed
        # shellcheck disable=SC2086
        echo "$snap_pkgs_not_installed" | xargs -t -L1 snap install
      elif $VERBOSE; then
        writeBlue "Not installing packages with Snap, they are all already installed."
      fi
    }
    install_snap_pkgs '' 'steam'
  fi
fi

# nix
if ! [ -f /etc/bash.bashrc.backup-before-nix ] && ! [ -d /nix/ ]; then
  writeBlue "Install Nix."
  sh <(curl -L https://nixos.org/nix/install) --daemon --yes
elif $UPDATE; then
  writeBlue "Update Nix."
  nix-env --install --file '<nixpkgs>' --attr nix cacert -I nixpkgs=channel:nixpkgs-unstable
  systemctl daemon-reload
  systemctl restart nix-daemon
elif $VERBOSE; then
  writeBlue "Not installing Nix, it is already installed."
fi

# upgrade
if $UPDATE; then
  writeBlue "Upgrade with APT."
  apt-get upgrade -y
  flatpak update -y
  if hash snap 2> /dev/null; then
    snap refresh
  fi
else
  if $VERBOSE; then
    writeBlue "Not updating with APT."
  fi
fi
