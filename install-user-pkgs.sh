#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

BASIC_SETUP=false
CURL_GH_HEADERS=()
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --basic|-b)
    BASIC_SETUP=true
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
Installs user packages.

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
      --gh <user:pw>       GitHub username and password
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE
  Basic setup is $BASIC_SETUP"
fi

export PATH="$HOME"/bin:"$PATH"

# nix home-manager
create_nix_env_file () {
  mkdir -p "$HOME"/.config/nixpkgs/
  cat <<EOF > "$HOME"/.config/nixpkgs/config.nix
{
  setup = {
    user = "$USER";
    wsl = $WSL;
    basicSetup = $BASIC_SETUP;
  };
}
EOF
}
installHomeManagerUsingFlakes () {
  download_nixpkgs_cache_index () {
    local filename
    filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr '[:upper:]' '[:lower:]')"
    mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
    wget -q -N "https://github.com/Mic92/nix-index-database/releases/latest/download/$filename"
    ln -f "$filename" files
  }
  if ! hash home-manager 2>/dev/null; then
    writeBlue "Install Nix home-manager."
    nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    create_nix_env_file
    nix run home-manager/master -- init --switch --show-trace --flake "$BASEDIR"/home-manager?submodules=1
    download_nixpkgs_cache_index
  elif $UPDATE; then
    writeBlue "Update Nix home-manager."
    nix-channel --update
    create_nix_env_file
    rm -f "$BASEDIR"/home-manager/flake.lock
    home-manager switch --show-trace --flake "$BASEDIR"/home-manager?submodules=1 --refresh
    download_nixpkgs_cache_index
  elif $VERBOSE; then
    writeBlue "Not installing Nix home-manager, it is already installed."
  fi
}
installHomeManagerUsingFlakes
