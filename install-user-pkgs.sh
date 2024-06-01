#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

BASIC_SETUP=false
CURL_GH_HEADERS=()
GH_TOKEN=''
UPDATE=false
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
    GH_TOKEN=$2
    shift 2
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

# bin
installBin () {
  if ! hash bin 2>/dev/null; then
    writeBlue "Install Bin."
    BIN_ARCH=''
    case `uname -m` in
      x86_64)
        BIN_ARCH=amd64
        ;;
      aarch64)
        BIN_ARCH=arm64
        ;;
      *)
        writeBlue "Bin will not be installed: unsupported architecture: `uname -m`"
        ;;
    esac
    if [ "$BIN_ARCH" != '' ]; then
      BIN_DL_URL=`githubReleaseDownloadUrl marcosnils/bin linux_$BIN_ARCH`
      curl -fsSL --output /tmp/bin "$BIN_DL_URL"
      chmod +x /tmp/bin
      mkdir -p "$HOME"/.config/bin/
      echo '{ "default_path": "'"$HOME"'/bin", "bins": { } }' > "$HOME"/.config/bin/config.json
      /tmp/bin install github.com/marcosnils/bin
      rm /tmp/bin
    fi
  elif $UPDATE; then
    writeBlue "Update Bin."
    export GITHUB_AUTH_TOKEN=$GH_TOKEN
    bin update bin --yes
  elif $VERBOSE; then
    writeBlue "Not installing Bin, it is already installed."
  fi
}
installBin

if $BASIC_SETUP; then
  exit
fi

# docker-show-context
installDockerShowContext () {
  if ! hash docker-show-context 2>/dev/null && ! [ -e "$HOME"/bin/docker-show-context ]; then
    writeBlue "Install docker-show-context."
    curl -fsSL --output "$HOME"/bin/docker-show-context https://github.com/pwaller/docker-show-context/releases/latest/download/docker-show-context_linux_amd64
    chmod +x "$HOME"/bin/docker-show-context
  elif $VERBOSE; then
    writeBlue "Not installing docker-show-context, it is already installed."
  fi
}
installDockerShowContext

# githooks
installGitHooks () {
  if ! [ -d "$HOME"/.githooks ]; then
    writeBlue "Install Githooks."
    githooks-cli installer --non-interactive
  elif $VERBOSE; then
    writeBlue "Not installing Githooks, it is already installed."
  fi
}
installGitHooks

# chart releaser - cr
installCR() {
  doInstallCR () {
    CR_DL_URL=`githubReleaseDownloadUrl helm/chart-releaser linux_amd64.tar.gz$`
    installTarToHomeBin "$CR_DL_URL" cr
  }
  if ! hash cr 2>/dev/null; then
    writeBlue "Install Chart releaser (CR)."
    doInstallCR
  elif $UPDATE; then
    CR_LATEST_VERSION=`githubLatestReleaseVersion helm/chart-releaser`
    if versionSmaller "`cr version | grep GitVersion | awk '{print $2}'`" "$CR_LATEST_VERSION"; then
      writeBlue "Update Chart releaser (CR)."
      doInstallCR
    elif $VERBOSE; then
      writeBlue "Not updating cr, it is already up to date."
    fi
  elif $VERBOSE; then
    writeBlue "Not installing Chart Releaser, it is already installed."
  fi
  }
installCR

# dotnet-install
installDotnetInstall () {
  if ! [ -e "$HOME"/bin/dotnet-install ]; then
    writeBlue "Install dotnet-install."
    # installBinToUsrLocalBin https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh
    installBinToHomeBin https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh
    ln -s "$HOME"/bin/dotnet-install.sh "$HOME"/bin/dotnet-install
  elif $VERBOSE; then
    writeBlue "Not installing dotnet-install, it is already installed."
  fi
}
installDotnetInstall

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
