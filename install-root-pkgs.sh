#!/bin/bash

set -euo pipefail

if [ "$EUID" != "0" ]; then
  echo "Please run this script as root"
  exit 2
fi

ALL_ARGS=$@
UPDATE=false
CLEAN=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
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

if $SHOW_HELP; then
  cat <<EOF
Installs root packages.

Usage:
  `readlink -f $0` [flags]

Flags:
  -c, --clean              Will clean installed packages.
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

install () {
  DEB=$1
  DEB=`echo "${DEB##*/}"` # get file name
  DEB=`echo "${DEB%%\?*}"` # remove query string
  DEB=`echo "${DEB%%\#*}"` # remove fragment
  DEB=/tmp/$DEB
  wget $1 -O $DEB
  apt-get install $DEB
  rm $DEB
}

addKey () {
  wget -q -O - $1 | apt-key add -
}

WSL=false
if grep microsoft /proc/version -q; then
  WSL=true
fi

REPOS=`apt-cache policy | grep http | awk '{print $2"/dists/"$3}' | sort -u`
printf -v REPOS $"$REPOS\n"
if [ "$REPOS" == "" ] || $UPDATE; then
  echo -e "\e[34mUpdate with APT.\e[0m"
  apt-get update
else
  if $VERBOSE; then
    echo "Not running apt update, repositories are already in place."
  fi
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
  echo -e "\e[34mInstall base packages with APT: $APT_PKGS_NOT_INSTALLED\e[0m"
  apt-get install -y $APT_PKGS_NOT_INSTALLED
else
  if $VERBOSE; then
    echo "Not installing any of the base packages, they are already installed."
  fi
fi

if ! [[ "$REPOS" =~ 'git-core/ppa' ]]; then
  echo -e "\e[34mAdd git PPA.\e[0m"
  add-apt-repository --yes ppa:git-core/ppa
else
  if $VERBOSE; then
    echo "Not adding Git PPA, it is already present."
  fi
fi
if ! [[ "$REPOS" =~ ubuntu.com/ubuntu/dists/.*/universe[[:space:]] ]]; then
  echo -e "\e[34mEnable the Universe repository.\e[0m"
  add-apt-repository universe --yes
else
  if $VERBOSE; then
    echo "Not adding the Universe repository, it is already present."
  fi
fi

# apt packages
APT_PKGS_TO_INSTALL=`echo "asciinema
autoconf
bat
bison
build-essential
cowsay
figlet
fontforge
git
gzip
htop
httpie
hub
iperf3
jq
libdb-dev
libffi-dev
libgdbm-dev
libgdbm6
libncurses5-dev
libreadline-dev
libssl-dev
libyaml-dev
locales
lsb-release
mosh
nmap
pandoc
pkg-config
python3-pip
socat
tmux
traceroute
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
  echo -e "\e[34mRun custom installations with APT: "$APT_PKGS_NOT_INSTALLED" \e[0m"
  apt-get install -y $APT_PKGS_NOT_INSTALLED
else
  if $VERBOSE; then
    echo "Not installing packages with PAT, they are already installed."
  fi
fi

# libssl1.1 (not available in Ubuntu 22.04)
curl -fsSL --output /tmp/libssl1.1.deb http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
dpkg -i /tmp/libssl1.1.deb
rm /tmp/libssl1.1.deb

# yq
if ! hash yq 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall YQ.\e[0m"
  if ! [[ "$REPOS" =~ 'rmescandon/yq' ]]; then
    echo -e "\e[34mAdd git PPA.\e[0m"
    if [[ `apt-key fingerprint CC86BB64 2> /dev/null` == '' ]]; then
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
    fi
    add-apt-repository --yes -u ppa:rmescandon/yq
  fi
  apt-get install yq -y
else
  if $VERBOSE; then
    echo "Not intalling Yq, it is already installed."
  fi
fi

# hashicorp vault
if ! hash vault 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Hashicorp Vault.\e[0m"
  wget https://releases.hashicorp.com/vault/1.11.0/vault_1.11.0_linux_amd64.zip -O /tmp/vault.zip
  rm -rf /tmp/vault
  unzip -qo /tmp/vault.zip -d /tmp/vault
  mv /tmp/vault/vault /usr/local/bin/
  rm /tmp/vault.zip
  rm -rf /tmp/vault
else
  if $VERBOSE; then
    echo "Not intalling Vault, it is already installed."
  fi
fi

# microsoft repos
if ! [[ "$REPOS" =~ packages.microsoft.com/ubuntu/.*/prod/dists/.*/main[[:space:]] ]]; then
  echo -e "\e[34mInstall Microsoft repos.\e[0m"
  install https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
  if ! [ -f /etc/apt/preferences.d/20-microsoft-packages ]; then
    cat <<EOF >> /etc/apt/preferences.d/20-microsoft-packages
Package: *
Pin: origin "packages.microsoft.com"
Pin-Priority: 1001
EOF
fi
  apt-get update
else
  if $VERBOSE; then
    echo "Not intalling the Microsoft repository, it is already present."
  fi
fi

# dotnet
APT_PKGS_TO_INSTALL=`echo "dotnet-sdk-6.0" | sort`
APT_PKGS_INSTALLED=`dpkg-query -W --no-pager --showformat='${Package}\n' | sort -u`
APT_PKGS_NOT_INSTALLED=`comm -23 <(echo "$APT_PKGS_TO_INSTALL") <(echo "$APT_PKGS_INSTALLED")`
if [ "$APT_PKGS_NOT_INSTALLED" != "" ]; then
  echo -e "\e[34mInstall .NET cli.\e[0m"
  apt-get install -y $APT_PKGS_NOT_INSTALLED
else
  if $VERBOSE; then
    echo "Not intalling .NET SDK, it is already installed."
  fi
fi

# az
if ! hash az 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Az.\e[0m"
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list
  apt-get update
  apt-get install -y azure-cli
else
  if $VERBOSE; then
    echo "Not intalling Az, it is already installed."
  fi
fi

# kubectl
if ! hash kubectl 2>/dev/null || $UPDATE; then
  if $WSL && ! $RUNNING_IN_CONTAINER; then
    echo -e "\e[34mNot installing Kubectl, already on WSL.\e[0m"
  else
    echo -e "\e[34mInstall Kubectl.\e[0m"
    addKey https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubectl
    # or curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
  fi
else
  if $VERBOSE; then
    echo "Not intalling Kubectl, it is already installed."
  fi
fi

# kubespy
if ! hash kubespy 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Kubespy.\e[0m"
  wget https://github.com/pulumi/kubespy/releases/download/v0.6.0/kubespy-v0.6.0-linux-amd64.tar.gz -O /tmp/kubespy.tar.gz
  rm /tmp/kubespy -rf
  mkdir -p /tmp/kubespy
  tar -xvzf /tmp/kubespy.tar.gz -C /tmp/kubespy/
  rm /tmp/kubespy.tar.gz
  mv /tmp/kubespy/kubespy /usr/local/bin/
  rm /tmp/kubespy -rf
else
  if $VERBOSE; then
    echo "Not intalling Kubespy, it is already installed."
  fi
fi

# google chrome
if ! hash google-chrome 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Google Chrome.\e[0m"
  addKey https://dl-ssl.google.com/linux/linux_signing_key.pub
  echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
  apt-get update
  apt-get install -y google-chrome-stable
else
  if $VERBOSE; then
    echo "Not intalling Google Chrome, it is already installed."
  fi
fi

# dive
if ! hash dive 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Dive.\e[0m"
  install https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
else
  if $VERBOSE; then
    echo "Not intalling Dive, it is already installed."
  fi
fi

# docker
if ! hash docker 2>/dev/null || $UPDATE; then
  if $RUNNING_IN_CONTAINER; then
    echo -e "\e[34mInstall Docker cli only.\e[0m"
    addKey https://download.docker.com/linux/ubuntu/gpg
    add-apt-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get install -y docker-ce-cli
  elif $WSL; then
    echo -e "\e[34mNot installing Docker, already on WSL.\e[0m"
  else
    echo -e "\e[34mInstall Docker.\e[0m"
    wget -q -O - https://get.docker.com | bash
  fi
else
  if $VERBOSE; then
    echo "Not intalling Docker, it is already installed."
  fi
fi

if $WSL && ! $RUNNING_IN_CONTAINER; then
  if ! [[ $APT_PKGS_INSTALLED =~ wslu ]]; then
    echo -e "\e[34mInstall WSL Utilities.\e[0m"
    add-apt-repository --yes ppa:wslutilities/wslu
    apt-get install -y wslu
  else
    if $VERBOSE; then
      echo "Not intalling WSL Utilities package, it is already installed."
    fi
  fi
fi

# helm 3
if ! hash helm 2>/dev/null || $UPDATE; then
  if ! hash helm3 2>/dev/null || $UPDATE; then
    echo -e "\e[34mInstall Helm 3.\e[0m"
    if [ -e /usr/local/bin/helm ]; then
      rm /usr/local/bin/helm
    fi
    wget -q -O - https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    mv /usr/local/bin/helm /usr/local/bin/helm3
    update-alternatives --install /usr/local/bin/helm helm /usr/local/bin/helm3 2
  else
    if $VERBOSE; then
      echo "Not intalling Helm 3, it is already installed."
    fi
  fi

  # helm 2
  if ! hash helm2 2>/dev/null || $UPDATE; then
    echo -e "\e[34mInstall Helm 2.\e[0m"
    wget https://get.helm.sh/helm-v2.17.0-linux-amd64.tar.gz -O /tmp/helm2.tar.gz
    rm /tmp/helm2 -rf
    mkdir -p /tmp/helm2
    tar -xvzf /tmp/helm2.tar.gz -C /tmp/helm2/
    rm /tmp/helm2.tar.gz
    mv /tmp/helm2/linux-amd64/helm /usr/local/bin/helm2
    mv /tmp/helm2/linux-amd64/tiller /usr/local/bin/
    rm /tmp/helm2 -rf
  else
    if $VERBOSE; then
      echo "Not intalling Helm 2, it is already installed."
    fi
  fi
  update-alternatives --install /usr/local/bin/helm helm /usr/local/bin/helm2 1
else
  if $VERBOSE; then
    echo "Not intalling Helm, it is already installed."
  fi
fi
update-alternatives --set helm /usr/local/bin/helm3


# chart releaser - cr
if ! hash cr 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Chart releaser (CR).\e[0m"
  wget https://github.com/helm/chart-releaser/releases/download/v1.4.0/chart-releaser_1.4.0_linux_amd64.tar.gz -O /tmp/cr.tar.gz
  rm /tmp/cr -rf
  mkdir -p /tmp/cr
  tar -xvzf /tmp/cr.tar.gz -C /tmp/cr/
  rm /tmp/cr.tar.gz
  mv /tmp/cr/cr /usr/local/bin/
  rm /tmp/cr -rf
else
  if $VERBOSE; then
    echo "Not intalling Chart Releaser, it is already installed."
  fi
fi

# istioctl
if ! hash istioctl 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Istioctl.\e[0m"
  wget -q -O - https://istio.io/downloadIstioctl | sh -
  mv $HOME/.istioctl/bin/istioctl /usr/local/bin/
  rm -rf $HOME/.istioctl
else
  if $VERBOSE; then
    echo "Not intalling Istioctl, it is already installed."
  fi
fi

# exa
if ! hash exa 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Exa.\e[0m"
  wget https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip -O /tmp/exa.zip
  rm -rf /tmp/exa
  unzip -qo /tmp/exa.zip -d /tmp/exa
  mv /tmp/exa/bin/exa /usr/local/bin/
  rm /tmp/exa.zip
  rm -rf /tmp/exa
else
  if $VERBOSE; then
    echo "Not intalling Exa, it is already installed."
  fi
fi

# terraform lint - tflint
if ! hash tflint 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall TFLint.\e[0m"
  wget https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip -O /tmp/tflint.zip
  rm -rf /tmp/tflint
  unzip -qo /tmp/tflint.zip -d /tmp/tflint
  mv /tmp/tflint/tflint /usr/local/bin/
  rm /tmp/tflint.zip
  rm -rf /tmp/tflint
else
  if $VERBOSE; then
    echo "Not intalling TFLint, it is already installed."
  fi
fi

# delta
if ! hash delta 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Delta.\e[0m"
  if dpkg -l git-delta &> /dev/null; then
    apt-get purge -y git-delta
  fi
  if dpkg -l delta-diff &> /dev/null; then
    apt-get purge -y delta-diff
  fi
  wget https://github.com/dandavison/delta/releases/download/0.13.0/git-delta_0.13.0_amd64.deb -O /tmp/delta.deb
  apt-get install /tmp/delta.deb
  rm /tmp/delta.deb
else
  if $VERBOSE; then
    echo "Not intalling Delta, it is already installed."
  fi
fi

# Github cli
if ! hash gh 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall Github cli.\e[0m"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  apt update
  apt install gh -y
else
  if $VERBOSE; then
    echo "Not intalling Github CLI, it is already installed."
  fi
fi

# k9s
if ! hash k9s 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall k9s.\e[0m"
  wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz -O /tmp/k9s.tar.gz
  mkdir /tmp/k9s/
  tar -xvzf /tmp/k9s.tar.gz -C /tmp/k9s/
  mv /tmp/k9s/k9s /usr/local/bin/
  rm -rf /tmp/k9s/
  rm /tmp/k9s.tar.gz
else
  if $VERBOSE; then
    echo "Not installing K9s, it is already installed."
  fi
fi

# aws cli
if ! hash aws 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall AWS cli.\e[0m"
  curl -fsSL --output /tmp/aws.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  unzip -qo /tmp/aws.zip -d /tmp/aws
  if hash aws 2>/dev/null; then
    /tmp/aws/aws/install --update
  else
    /tmp/aws/aws/install
  fi
  rm /tmp/aws.zip
  rm /tmp/aws -rf
else
  if $VERBOSE; then
    echo "Not installing AWS cli, it is already installed."
  fi
fi

# k3d
if ! hash k3d 2>/dev/null || $UPDATE; then
  curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
else
  if $VERBOSE; then
    echo "Not installing k3d, it is already installed."
  fi
fi

# starship
if ! hash starship 2>/dev/null || $UPDATE; then
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
else
  if $VERBOSE; then
    echo "Not installing Starship, it is already installed."
  fi
fi

# act
if ! hash act 2>/dev/null || $UPDATE; then
  curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin
else
  if $VERBOSE; then
    echo "Not installing Act, it is already installed."
  fi
fi

# upgrade
if $UPDATE; then
  echo -e "\e[34mUpgrade with APT.\e[0m"
  apt-get upgrade -y
else
  if $VERBOSE; then
    echo "Not updating with APT."
  fi
fi

if $CLEAN; then
  echo -e "\e[34mCleanning up packages.\e[0m"
  apt-get autoremove -y
else
  if $VERBOSE; then
    echo "Not auto removing with APT."
  fi
fi
