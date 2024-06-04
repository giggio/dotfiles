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
  cat <<EOF > "$HOME"/.config/nix/.env.nix
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
    nix run home-manager/master -- init --switch --show-trace --flake "$BASEDIR"/config/home-manager --impure
    download_nixpkgs_cache_index
  elif $UPDATE; then
    writeBlue "Update Nix home-manager."
    nix-channel --update
    create_nix_env_file
    rm -f "$BASEDIR"/config/home-manager/flake.lock
    home-manager switch --show-trace --flake "$BASEDIR"/config/home-manager --impure --refresh
    download_nixpkgs_cache_index
  elif $VERBOSE; then
    writeBlue "Not installing Nix home-manager, it is already installed."
  fi
}
installHomeManagerUsingFlakes

if $BASIC_SETUP; then
  exit
fi

# vault
installVault () {
  # see urls and details at: https://developer.hashicorp.com/vault/install
  # see release info at: https://github.com/hashicorp/vault/releases/tag/v1.15.6
  local vault_current_version
  if hash vault 2>/dev/null; then
    if ! $UPDATE; then
      if $VERBOSE; then
        writeBlue "Not installing Hashicorp Vault, it is already installed."
      fi
      return
    fi
    writeBlue "Update Hashicorp Vault."
    vault_current_version=`vault version | awk '{print $2}'`
  else
    writeBlue "Install Hashicorp Vault."
    vault_current_version=0.0.1
  fi
  local vault_latest_version
  vault_latest_version=`githubLatestReleaseVersion hashicorp/vault` # this will be like: v1.15.6
  if [[ "$vault_latest_version" == v* ]]; then
    vault_latest_version="${vault_latest_version:1}"
  fi
  if versionSmaller "$vault_current_version" "$vault_latest_version"; then
    installZipToHomeBin "https://releases.hashicorp.com/vault/$vault_latest_version/vault_${vault_latest_version}_linux_amd64.zip" vault
  else
    writeBlue "Not updating Vault, it is already up to date."
  fi
}
installVault

# terraform
installTerraform () {
  # see urls and details at: https://developer.hashicorp.com/terraform/install
  # see release info at: https://github.com/hashicorp/terraform/releases/tag/v1.7.4
  local terraform_current_version
  if hash terraform 2>/dev/null; then
    if ! $UPDATE; then
      if $VERBOSE; then
        writeBlue "Not installing Hashicorp Terraform, it is already installed."
      fi
      return
    fi
    writeBlue "Update Terraform."
    terraform_current_version=`terraform --version | head -n1 | awk '{ print $2 }'`
  else
    writeBlue "Install Terraform."
    terraform_current_version=0.0.1
  fi
  local terraform_latest_version
  terraform_latest_version=`githubLatestReleaseVersion hashicorp/terraform` # this will be like: v1.15.6
  if [[ "$terraform_latest_version" == v* ]]; then
    terraform_latest_version="${terraform_latest_version:1}"
  fi
  if versionSmaller "$terraform_current_version" "$terraform_latest_version"; then
    installZipToHomeBin "https://releases.hashicorp.com/terraform/$terraform_latest_version/terraform_${terraform_latest_version}_linux_amd64.zip" terraform
  else
    writeBlue "Not updating Terraform, it is already up to date."
  fi
}
installTerraform
