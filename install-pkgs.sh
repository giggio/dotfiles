#!/bin/bash

set -euo pipefail

install () {
  DEB=/tmp/pgk.deb
  wget $1 -O $DEB
  apt-get install $DEB
  rm $DEB
}

addKey () {
  wget -q -O - $1 | apt-key add -
}

echo -e "\e[34mUpdate and upgrade with APT.\e[0m"
apt-get update
apt-get upgrade -y
echo -e "\e[34mInstall base packages with APT.\e[0m"
apt-get install -y apt-transport-https ca-certificates curl wget \
  gnupg gnupg-agent gnupg2 software-properties-common
echo -e "\e[34mEnable the Universe repository.\e[0m"
add-apt-repository universe
echo -e "\e[34mInstall other packages with APT.\e[0m"
add-apt-repository --yes ppa:git-core/ppa
# apt-get update
apt-get install -y \
  asciinema \
  autoconf \
  bat \
  bison \
  build-essential \
  cowsay \
  figlet \
  fontforge \
  fzf \
  git \
  gzip \
  htop \
  httpie \
  hub \
  jq \
  libdb-dev \
  libffi-dev \
  libgdbm-dev \
  libgdbm6 \
  libncurses5-dev \
  libreadline6-dev \
  libssl-dev \
  libyaml-dev \
  locales \
  lsb-release \
  mosh \
  nmap \
  python3-pip \
  socat \
  tmux \
  traceroute \
  unzip \
  vim \
  w3m \
  whois \
  zip \
  zlib1g-dev

echo -e "\e[34mRun custom installations.\e[0m"

# microsoft repos
install https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
apt-get update

# dotnet
apt-get install -y dotnet-sdk-3.1

# az
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y azure-cli

# kubectl
addKey https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
# or curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

# google chrome
addKey https://dl-ssl.google.com/linux/linux_signing_key.pub
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get install -y google-chrome-stable

# dive
install https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb

if grep [Mm]icrosoft /proc/version > /dev/null; then
  export WSL=true
else
  export WSL=false
fi
if grep docker /proc/1/cgroup -qa; then
  export RUNNING_IN_CONTAINER=true
else
  export RUNNING_IN_CONTAINER=false
fi
if $WSL || $RUNNING_IN_CONTAINER; then
  if ! hash docker 2>/dev/null; then
    addKey https://download.docker.com/linux/ubuntu/gpg
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get install -y docker-ce-cli
  fi
else
  wget -q -O - https://get.docker.com | bash
fi

# helm 3
if ! [ -L /usr/local/bin/helm ]; then
  wget -q -O - https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  mv /usr/local/bin/helm /usr/local/bin/helm3
  ln -s /usr/local/bin/helm3 /usr/local/bin/helm
fi

# helm 2
if ! [ -f /usr/local/bin/helm2 ]; then
  wget https://get.helm.sh/helm-v2.16.7-linux-amd64.tar.gz -O /tmp/helm2.tar.gz
  rm /tmp/helm2 -rf
  mkdir -p /tmp/helm2
  tar -xvzf /tmp/helm2.tar.gz -C /tmp/helm2/
  rm /tmp/helm2.tar.gz
  mv /tmp/helm2/linux-amd64/helm /usr/local/bin/helm2
  mv /tmp/helm2/linux-amd64/tiller /usr/local/bin/
  rm /tmp/helm2 -rf
fi

# istioctl
wget -q -O - https://istio.io/downloadIstioctl | sh -
mv $HOME/.istioctl/bin/istioctl /usr/local/bin/
rm -rf $HOME/.istioctl

# pip
# wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
# python3 /tmp/get-pip.py

# vsts-cli
# wget -q -O - https://aka.ms/install-vsts-cli | bash
# apt-get install -y libssl-dev libffi-dev python3-dev build-essential
# sudo add-apt-repository --yes ppa:deadsnakes/ppa
# sudo apt-get install -y python3.7

# exa
wget https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip -O /tmp/exa.zip
rm -rf /tmp/exa
unzip /tmp/exa.zip -d /tmp/exa
mv /tmp/exa/exa-linux-x86_64 /usr/local/bin/exa
rm /tmp/exa.zip
rm -rf /tmp/exa

# terraform
wget https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip -O /tmp/tf.zip
rm -rf /tmp/tf
unzip /tmp/tf.zip -d /tmp/tf
mv /tmp/tf/terraform /usr/local/bin/
rm /tmp/tf.zip
rm -rf /tmp/tf

# delta
wget https://github.com/dandavison/delta/releases/download/0.1.1/git-delta_0.1.1_amd64.deb -O /tmp/delta.deb
apt-get install /tmp/delta.deb
rm /tmp/delta.deb

# upgrade
echo -e "\e[34mUpgrade with APT.\e[0m"
apt-get upgrade -y
