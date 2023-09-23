#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $BASEDIR/_common-setup.sh

if [ "$EUID" != "0" ]; then
  die "Please do not run this script as root"
fi

GH_USERNAME_PASSWORD=''
CURL_OPTION_GH_USERNAME_PASSWORD=''
UPDATE=false
CLEAN=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gh)
    GH_USERNAME_PASSWORD=$2
    CURL_OPTION_GH_USERNAME_PASSWORD=" --user $2 "
    shift
    shift
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
  `readlink -f $0` [flags]

Flags:
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
  Github username and password is $GH_USERNAME_PASSWORD
  Clean is $CLEAN"
fi

WSL=false
if grep microsoft /proc/version -q; then
  WSL=true
fi

REPOS=`apt-cache policy | grep http | awk '{print $2"/dists/"$3}' | sort -u`
printf -v REPOS $"$REPOS\n"
if [ "$REPOS" == "" ] || $UPDATE; then
  writeBlue "Update APT metadata."
  apt-get update
elif $VERBOSE; then
  writeBlue "Not running apt-get update, repositories are already in place."
fi

APT_PKGS_INSTALLED=`dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u`
APT_PKGS_TO_INSTALL=`echo "apt-transport-https
ca-certificates
curl
wget
gnupg
gnupg-agent
gnupg2
silversearcher-ag
software-properties-common" | sort`
APT_PKGS_NOT_INSTALLED=`comm -23 <(echo "$APT_PKGS_TO_INSTALL") <(echo "$APT_PKGS_INSTALLED")`
if [ "$APT_PKGS_NOT_INSTALLED" != "" ]; then
  writeBlue "Install base packages with APT: $APT_PKGS_NOT_INSTALLED"
  apt-get install -y $APT_PKGS_NOT_INSTALLED
elif $VERBOSE; then
  writeBlue "Not installing any of the base packages, they are already installed."
fi

if ! [[ "$REPOS" =~ 'git-core/ppa' ]]; then
  writeBlue "Add git PPA."
  add-apt-repository --yes ppa:git-core/ppa
elif $VERBOSE; then
  writeBlue "Not adding Git PPA, it is already present."
fi
if ! [[ "$REPOS" =~ ubuntu.com/ubuntu/dists/.*/universe[[:space:]] ]]; then
  writeBlue "Enable the Universe repository."
  add-apt-repository universe --yes
elif $VERBOSE; then
  writeBlue "Not adding the Universe repository, it is already present."
fi

# apt packages
APT_PKGS_TO_INSTALL=`echo "asciinema
autoconf
bat
bison
build-essential
cowsay
figlet
file
fontforge
git
gzip
htop
httpie
hub
inotify-tools
iperf3
jq
libdb-dev
libffi-dev
libgdbm-dev
libgdbm6
libncurses5-dev
libpython3-dev
libreadline-dev
libssl-dev
libtext-lorem-perl
libyaml-dev
locales
lsb-release
mosh
neovim
nmap
pandoc
pkg-config
python3-pip
shellcheck
socat
scdaemon
tmux
traceroute
tree
unzip
vim
w3m
whois
zip
zlib1g-dev" | sort`
# todo, add ripgrep when issue is fixed (move from cargo install)
# see: https://github.com/sharkdp/bat/issues/938
APT_PKGS_INSTALLED=`dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u`
APT_PKGS_NOT_INSTALLED=`comm -23 <(echo "$APT_PKGS_TO_INSTALL") <(echo "$APT_PKGS_INSTALLED")`
if [ "$APT_PKGS_NOT_INSTALLED" != "" ]; then
  writeBlue "Run custom installations with APT: "$APT_PKGS_NOT_INSTALLED" "
  apt-get install -y $APT_PKGS_NOT_INSTALLED
elif $VERBOSE; then
  writeBlue "Not installing packages with APT, they are all already installed."
fi

# build Vim 9 if needed
VIM_VERSION=`vim --version | grep 'Vi IM' | sed -E 's/.*([0-9]+\.[0-9]+).*/\1/g'`
installVim () {
  sed -i 's/#CONF_OPT_PYTHON3 = --enable-python3interp$/CONF_OPT_PYTHON3 = --enable-python3interp/' src/Makefile
  make
  make install
  which vim
  vim --version
}
if dpkg --compare-versions "$VIM_VERSION" lt 9.0; then
  writeBlue "Install Vim from source."
  if [ -d $HOME/p/vim ];then rm -rf $HOME/p/vim; fi
  mkdir -p $HOME/p/
  git clone https://github.com/vim/vim $HOME/p/vim
  pushd $HOME/p/vim > /dev/null
  installVim
  popd > /dev/null
elif $UPDATE; then
  if ! [ -d $HOME/p/vim ];then
    mkdir -p $HOME/p/
    git clone https://github.com/vim/vim $HOME/p/vim
  fi
  writeBlue "Update Vim from source."
  pushd $HOME/p/vim > /dev/null
  git clean -fd > /dev/null
  git checkout -- :/ > /dev/null
  if [ "`git rev-parse --abbrev-ref HEAD`" != "master" ]; then
    git checkout master > /dev/null
  fi
  git reset --hard origin/master > /dev/null
  git fetch origin master > /dev/null
  if `checkIfNeedsGitPull`; then
    writeBlue "Vim needs update."
    git pull origin master
    installVim
  elif $VERBOSE; then
    writeBlue "Not updating Vim, it is already up to date."
  fi
  popd > /dev/null
fi

# libssl1.1 (not available in Ubuntu 22.04)
if ! dpkg-query --no-pager --showformat='${Package}\n' --show 'libssl1.1' > /dev/null; then
  writeBlue "Install libssl1.1."
  curl -fsSL --output /tmp/libssl1.1.deb http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
  dpkg -i /tmp/libssl1.1.deb
  rm /tmp/libssl1.1.deb
fi

# google chrome
if ! hash google-chrome 2>/dev/null; then
  writeBlue "Install Google Chrome."
  addSourceListAndKey https://dl-ssl.google.com/linux/linux_signing_key.pub 'http://dl.google.com/linux/chrome/deb/ stable main' google-chrome google
  apt-get install -y google-chrome-stable
elif $VERBOSE; then
  writeBlue "Not intalling Google Chrome, it is already installed."
fi

# yq
if ! hash yq 2>/dev/null; then
  writeBlue "Install YQ."
  if ! [[ "$REPOS" =~ 'rmescandon/yq' ]]; then
    writeBlue "Add git PPA."
    if [[ `apt-key fingerprint CC86BB64 2> /dev/null` == '' ]]; then
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
    fi
    add-apt-repository --yes -u ppa:rmescandon/yq
  fi
  apt-get install yq -y
elif $VERBOSE; then
  writeBlue "Not intalling Yq, it is already installed."
fi

# hashicorp vault
if ! hash vault 2>/dev/null; then
  writeBlue "Install Hashicorp Vault."
  if [ -e /usr/local/bin/vault ]; then # todo remove after a while, there was no repo for vault, so this is a temporary cleanup. It's been here since 2022-10-10
    rm /usr/local/bin/vault
  fi
  addSourceListAndKey https://apt.releases.hashicorp.com/gpg "https://apt.releases.hashicorp.com `lsb_release -cs` main" hashicorp
  apt-get install -y vault
fi

# microsoft repos
if ! [ -f /etc/apt/trusted.gpg.d/microsoft-keyring.gpg ] || ! [ -f /etc/apt/sources.list.d/microsoft.list ]; then
  writeBlue "Add Microsoft keyring and list file."
  addSourceListAndKey https://packages.microsoft.com/keys/microsoft.asc "https://packages.microsoft.com/ubuntu/22.04/prod `lsb_release -cs` main" microsoft
elif $VERBOSE; then
  writeBlue "Not intalling the Microsoft repository, it is already present."
fi
if ! [ -f /etc/apt/preferences.d/20-microsoft-packages ]; then
  writeBlue "Adding pin priority to Microsoft packages to /etc/apt/preferences.d/20-microsoft-packages."
  cat <<EOF >> /etc/apt/preferences.d/20-microsoft-packages
Package: *
Pin: origin "packages.microsoft.com"
Pin-Priority: 1001
EOF
elif $VERBOSE; then
  writeBlue "Not adding pin priority to Microsoft packages, it is already present."
fi

# dotnet
APT_PKGS_TO_INSTALL=`echo "dotnet-runtime-6.0
dotnet-sdk-6.0
dotnet-runtime-7.0
dotnet-sdk-7.0" | sort`
APT_PKGS_INSTALLED=`dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u`
APT_PKGS_NOT_INSTALLED=`comm -23 <(echo "$APT_PKGS_TO_INSTALL") <(echo "$APT_PKGS_INSTALLED")`
if [ "$APT_PKGS_NOT_INSTALLED" != "" ]; then
  writeBlue "Install .NET cli."
  apt-get install -y $APT_PKGS_NOT_INSTALLED
elif $VERBOSE; then
  writeBlue "Not intalling .NET SDK, it is already installed."
fi

# az
if ! hash az 2>/dev/null; then
  writeBlue "Install Az."
  addSourcesList "https://packages.microsoft.com/repos/azure-cli/ `lsb_release -cs` main" azure-cli microsoft
  apt-get install -y azure-cli
elif $VERBOSE; then
  writeBlue "Not intalling Az, it is already installed."
fi

# kubectl
if ! hash kubectl 2>/dev/null || ( $WSL && [[ "`which kubectl`" =~ '/mnt/' ]] ); then
  writeBlue "Install Kubectl."
  addSourceListAndKey https://packages.cloud.google.com/apt/doc/apt-key.gpg 'https://apt.kubernetes.io/ kubernetes-xenial main' kubernetes
  apt-get install -y kubectl
elif $VERBOSE; then
  writeBlue "Not intalling Kubectl, it is already installed."
fi

# kubespy
installKubespy () {
  KUBESPY_DL_URL=`githubReleaseDownloadUrl pulumi/kubespy linux`
  curl -fsSL --output /tmp/kubespy.tar.gz $KUBESPY_DL_URL
  rm /tmp/kubespy -rf
  mkdir -p /tmp/kubespy
  tar -xvzf /tmp/kubespy.tar.gz -C /tmp/kubespy/
  rm /tmp/kubespy.tar.gz
  mv /tmp/kubespy/kubespy /usr/local/bin/
  rm /tmp/kubespy -rf
}
if ! hash kubespy 2>/dev/null; then
  writeBlue "Install Kubespy."
  installKubespy
elif $UPDATE; then
  KUBESPY_LATEST_VERSION=`githubLatestReleaseVersion pulumi/kubespy`
  if versionsDifferent `kubespy version` "$KUBESPY_LATEST_VERSION"; then
    writeBlue "Update Kubespy."
    installKubespy
  elif $VERBOSE; then
    writeBlue "Not updating kubespy, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Kubespy, it is already installed."
fi

# dive
installDive () {
  DIVE_DL_URL=`githubReleaseDownloadUrl wagoodman/dive linux_amd64.deb`
  installDeb $DIVE_DL_URL
}
if ! hash dive 2>/dev/null; then
  writeBlue "Install Dive."
  installDive
elif $UPDATE; then
  DIVE_LATEST_VERSION=`githubLatestReleaseVersion wagoodman/dive`
  if versionsDifferent  `dive --version | cut -f2 -d' '` "$DIVE_LATEST_VERSION"; then
    writeBlue "Update Dive."
    installDive
  elif $VERBOSE; then
    writeBlue "Not updating Dive, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Dive, it is already installed."
fi

# docker and docker-compose
if ! hash docker 2>/dev/null; then
  if $RUNNING_IN_CONTAINER || $WSL; then
    writeBlue "Install Docker cli and compose plugin with apt, without daemon."
    addSourceListAndKey https://download.docker.com/linux/ubuntu/gpg "https://download.docker.com/linux/ubuntu `lsb_release -cs` stable" docker
    apt-get install -y docker-ce-cli docker-compose-plugin
  else
    writeBlue "Install Docker and compose plugin through install script."
    curl -fsSL https://get.docker.com | bash
  fi
  curl -fsSL https://raw.githubusercontent.com/docker/compose-switch/master/install_on_linux.sh | sh
elif $VERBOSE; then
  writeBlue "Not intalling Docker, it is already installed."
fi

# wslu
if $WSL && ! $RUNNING_IN_CONTAINER; then
  if [[ $APT_PKGS_INSTALLED =~ ubuntu-wsl ]]; then
    apt-get remove ubuntu-wsl -y
  fi
  if ! [[ $APT_PKGS_INSTALLED =~ (^|$'\n')wslu($|$'\n') ]]; then
    writeBlue "Install WSL Utilities."
    add-apt-repository --yes ppa:wslutilities/wslu
    apt-get install -y wslu
  elif $VERBOSE; then
    writeBlue "Not intalling WSL Utilities package, it is already installed."
  fi
fi

# helm 2 and 3
installHelm3 () {
  curl -fsSL --output /tmp/get-helm-3 https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  sed -i 's/${BINARY_NAME:="helm"}/${BINARY_NAME:="helm3"}/' /tmp/get-helm-3
  chmod +x /tmp/get-helm-3
  /tmp/get-helm-3
  rm /tmp/get-helm-3
}
if ! hash helm 2>/dev/null; then
  if ! hash helm3 2>/dev/null; then
    writeBlue "Install Helm 3."
    if [ -e /usr/local/bin/helm ]; then
      rm /usr/local/bin/helm
    fi
    installHelm3
  elif $VERBOSE; then
    writeBlue "Not intalling Helm 3, it is already installed."
  fi

  # helm 2
  if ! hash helm2 2>/dev/null; then
    writeBlue "Install Helm 2."
    curl -fsSL --output /tmp/helm2.tar.gz https://get.helm.sh/helm-v2.17.0-linux-amd64.tar.gz
    rm /tmp/helm2 -rf
    mkdir -p /tmp/helm2
    tar -xvzf /tmp/helm2.tar.gz -C /tmp/helm2/
    rm /tmp/helm2.tar.gz
    mv /tmp/helm2/linux-amd64/helm /usr/local/bin/helm2
    mv /tmp/helm2/linux-amd64/tiller /usr/local/bin/
    rm /tmp/helm2 -rf
  elif $VERBOSE; then
    writeBlue "Not intalling Helm 2, it is already installed."
  fi
  update-alternatives --install /usr/local/bin/helm helm /usr/local/bin/helm2 1
  update-alternatives --install /usr/local/bin/helm helm /usr/local/bin/helm3 2
  update-alternatives --set helm /usr/local/bin/helm3
elif $UPDATE; then
  HELM3_LATEST_VERSION=`githubLatestReleaseVersion helm/helm`
  if [ `helm3 version | sed -E 's/.*\{Version:"v([0-9]+\.[0-9]+\.[0-9]+).*/\1/'` != "$HELM3_LATEST_VERSION" ]; then
    writeBlue "Update Helm 3."
    installHelm3
  elif $VERBOSE; then
    writeBlue "Not updating helm 3, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Helm, it is already installed."
fi

# chart releaser - cr
installCR () {
  CR_DL_URL=`githubReleaseDownloadUrl helm/chart-releaser linux_amd64.tar.gz$`
  curl -fsSL --output /tmp/cr.tar.gz $CR_DL_URL
  rm /tmp/cr -rf
  mkdir -p /tmp/cr
  tar -xvzf /tmp/cr.tar.gz -C /tmp/cr/
  rm /tmp/cr.tar.gz
  mv /tmp/cr/cr /usr/local/bin/
  rm /tmp/cr -rf
}
if ! hash cr 2>/dev/null; then
  writeBlue "Install Chart releaser (CR)."
  installCR
elif $UPDATE; then
  CR_LATEST_VERSION=`githubLatestReleaseVersion helm/chart-releaser`
  if versionsDifferent  "`cr version | grep GitVersion | awk '{print $2}'`" "$CR_LATEST_VERSION"; then
    writeBlue "Update Chart releaser (CR)."
    installCR
  elif $VERBOSE; then
    writeBlue "Not updating cr, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Chart Releaser, it is already installed."
fi

# istioctl
installIstio () {
  curl -fsSL https://istio.io/downloadIstioctl | sh -
  mv $HOME/.istioctl/bin/istioctl /usr/local/bin/
  rm -rf $HOME/.istioctl
}
if ! hash istioctl 2>/dev/null; then
  writeBlue "Install Istioctl."
  installIstio
elif $UPDATE; then
  ISTIO_LATEST_VERSION=`githubLatestReleaseVersion istio/istio`
  if [ "`istioctl version --remote=false`" != "$ISTIO_LATEST_VERSION" ]; then
    writeBlue "Update Istioctl."
    installIstio
  elif $VERBOSE; then
    writeBlue "Not updating istioctl, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Istioctl, it is already installed."
fi

# eza (exa fork)
# amd64, arm64, armhf
ARCH=''
case `uname -m` in
  x86_64)
    ARCH=x86_64
    ;;
  aarch64)
    ARCH=aarch64
    ;;
  armv7l)
    ARCH=arm
    ;;
  *)
    writeBlue "Eza will not be installed: unsupported architecture: `uname -m`"
    ;;
esac
installEza () {
  EZA_DL_URL=`githubReleaseDownloadUrl eza-community/eza "^eza_$ARCH-unknown-linux"`
  curl -fsSL --output /tmp/eza.tar.gz "$EZA_DL_URL"
  rm -rf /tmp/eza
  mkdir /tmp/eza
  tar -xvzf /tmp/eza.tar.gz -C /tmp/eza/
  mv /tmp/eza/eza /usr/local/bin/
  rm /tmp/eza.tar.gz
  rm -rf /tmp/eza
}
if [ "$ARCH" != '' ]; then
  if ! hash eza 2>/dev/null; then
    writeBlue "Install Eza."
    installEza
  elif $UPDATE; then
    EZA_LATEST_VERSION=`githubLatestReleaseVersion eza-community/eza`
    if versionsDifferent "`eza --version | grep --color=never +git | cut -d' ' -f1`" "$EZA_LATEST_VERSION"; then
      writeBlue "Update Eza."
      installEza
    elif $VERBOSE; then
      writeBlue "Not updating eza, it is already up to date."
    fi
  elif $VERBOSE; then
    writeBlue "Not intalling Eza, it is already installed."
  fi
fi

# terraform lint - tflint
installTFLint () {
  curl -fsSL --output /tmp/tflint.zip https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
  rm -rf /tmp/tflint
  unzip -qo /tmp/tflint.zip -d /tmp/tflint
  mv /tmp/tflint/tflint /usr/local/bin/
  rm /tmp/tflint.zip
  rm -rf /tmp/tflint
}
if ! hash tflint 2>/dev/null; then
  writeBlue "Install TFLint."
  installTFLint
elif $UPDATE; then
  TFLINT_LATEST_VERSION=`githubLatestReleaseVersion terraform-linters/tflint`
  if [ `tflint --version | head -n1 | sed -E 's/.*([0-9]+\.[0-9]+\.[0-9]+)$/\1/'` != "$TFLINT_LATEST_VERSION" ]; then
    writeBlue "Update TFLint."
    installTFLint
  elif $VERBOSE; then
    writeBlue "Not updating Tflint, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling TFLint, it is already installed."
fi

# delta
ARCH=''
case `uname -m` in
  x86_64)
    ARCH=amd64
    ;;
  aarch64)
    ARCH=arm64
    ;;
  armv7l)
    ARCH=armhf
    ;;
  *)
    writeBlue "Delta will not be installed: unsupported architecture: `uname -m`"
    ;;
esac
installDelta () {
  DELTA_DL_URL=`githubReleaseDownloadUrl dandavison/delta "^git-delta(?!-musl).*_$ARCH.deb$"`
  installDeb $DELTA_DL_URL
}
if [ "$ARCH" != '' ]; then
  if ! hash delta 2>/dev/null; then
    writeBlue "Install Delta."
    if dpkg -l git-delta &> /dev/null; then
      apt-get purge -y git-delta
    fi
    if dpkg -l delta-diff &> /dev/null; then
      apt-get purge -y delta-diff
    fi
    installDelta
  elif $UPDATE; then
    DELTA_LATEST_VERSION=`githubLatestReleaseVersion dandavison/delta`
    if [ `delta --version | awk '{print $2}'` != "$DELTA_LATEST_VERSION" ]; then
      writeBlue "Update Delta."
      installDelta
    elif $VERBOSE; then
      writeBlue "Not updating Delta, it is already up to date."
    fi
  elif $VERBOSE; then
    writeBlue "Not intalling Delta, it is already installed."
  fi
fi

# Github cli
if ! hash gh 2>/dev/null; then
  writeBlue "Install Github cli."
  addSourceListAndKey https://cli.github.com/packages/githubcli-archive-keyring.gpg "https://cli.github.com/packages stable main" githubcli
  apt-get install gh -y
elif $VERBOSE; then
  writeBlue "Not intalling Github CLI, it is already installed."
fi

# k9s
installK9s () {
  curl -fsSL --output /tmp/k9s.tar.gz https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
  mkdir /tmp/k9s/
  tar -xvzf /tmp/k9s.tar.gz -C /tmp/k9s/
  mv /tmp/k9s/k9s /usr/local/bin/
  rm -rf /tmp/k9s/
  rm /tmp/k9s.tar.gz
}
if ! hash k9s 2>/dev/null; then
  writeBlue "Install k9s."
  installK9s
elif $UPDATE; then
  K9S_LATEST_VERSION=`githubLatestReleaseVersion derailed/k9s`
  if versionsDifferent "`k9s version --short | grep Version | awk '{print $2}'`" "$K9S_LATEST_VERSION"; then
    writeBlue "Update k9s."
    installK9s
  elif $VERBOSE; then
    writeBlue "Not updating k9s, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not installing K9s, it is already installed."
fi

# aws cli
installAWS () {
  curl -fsSL --output /tmp/aws.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  unzip -qo /tmp/aws.zip -d /tmp/aws
  if hash aws 2>/dev/null; then
    /tmp/aws/aws/install --update
  else
    /tmp/aws/aws/install
  fi
  rm /tmp/aws.zip
  rm /tmp/aws -rf
}
if ! hash aws 2>/dev/null; then
  writeBlue "Install AWS cli."
  installAWS
elif $UPDATE; then
  AWS_LATEST_VERSION=`githubLatestTagByVersion aws/aws-cli`
  if [ "`aws --version | sed -E 's/aws-cli\/([0-9]+\.[0-9]+\.[0-9]+).*/\1/'`" != "$AWS_LATEST_VERSION" ]; then
    writeBlue "Update AWS cli."
    installAWS
  elif $VERBOSE; then
    writeBlue "Not updating aws, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not installing AWS cli, it is already installed."
fi

# k3d
if ! hash k3d 2>/dev/null; then
  writeBlue "Install K3d."
  curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
elif $UPDATE; then
  K3D_LATEST_VERSION=`githubLatestReleaseVersion rancher/k3d`
  if versionsDifferent  "`k3d --version | grep --color=never k3d | awk '{print $3}'`" "$K3D_LATEST_VERSION"]; then
    writeBlue "Update K3d."
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
  elif $VERBOSE; then
    writeBlue "Not updating k3d, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not installing k3d, it is already installed."
fi

# starship
if ! hash starship 2>/dev/null; then
  writeBlue "Install Starship."
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
elif $UPDATE; then
  STARSHIP_LATEST_VERSION=`githubLatestReleaseVersion starship/starship`
  if [ `starship --version | grep --color=never starship | awk '{print $2}'` != "$STARSHIP_LATEST_VERSION" ]; then
    writeBlue "Update Starship."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
  elif $VERBOSE; then
    writeBlue "Not updating starship, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not installing Starship, it is already installed."
fi

# act
if ! hash act 2>/dev/null; then
  writeBlue "Install Act."
  curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin
elif $UPDATE; then
  ACT_LATEST_VERSION=`githubLatestReleaseVersion nektos/act`
  if [ `act --version | awk '{print $3}'` != "$ACT_LATEST_VERSION" ]; then
    writeBlue "Update Act."
    curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin
  elif $VERBOSE; then
    writeBlue "Not updating act, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not installing Act, it is already installed."
fi

# carapace
installCarapace () {
  CARAPACE_DL_URL=`githubReleaseDownloadUrl rsteube/carapace-bin linux_amd64.deb`
  installDeb $CARAPACE_DL_URL
}
if ! hash carapace 2>/dev/null; then
  writeBlue "Install Carapace."
  installCarapace
elif $UPDATE; then
  CARAPACE_LATEST_VERSION=`githubLatestReleaseVersion rsteube/carapace-bin`
  if versionsDifferent  `carapace --version` "$CARAPACE_LATEST_VERSION"; then
    writeBlue "Update Carapace."
    installCarapace
  elif $VERBOSE; then
    writeBlue "Not updating Carapace, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Carapace, it is already installed."
fi

# kn / knative
installKnative () {
  KNATIVE_DL_URL=`githubReleaseDownloadUrl knative/client kn-linux-amd64`
  installBinToUsrLocalBin "$KNATIVE_DL_URL" kn
}
if ! hash kn 2>/dev/null; then
  writeBlue "Install Knative."
  installKnative
elif $UPDATE; then
  KN_ALL_RELEASES=`githubAllReleasesVersions knative/client | grep --color=never knative | sed -E 's/knative-(.*)/\1/'`
  KN_LATEST_VERSION=`getLatestVersion "$KN_ALL_RELEASES"`
  if versionsDifferent "`kn version -oyaml | grep --color=never Version | awk '{print $2}'`" "$KN_LATEST_VERSION"; then
    writeBlue "Update Knative."
    installKnative
  elif $VERBOSE; then
    writeBlue "Not updating Knative, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Knative, it is already installed."
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

if $CLEAN; then
  writeBlue "Cleanning up packages."
  apt-get autoremove -y
elif $VERBOSE; then
  writeBlue "Not auto removing with APT."
fi
