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
echo -e "\e[34mAdd git PPA.\e[0m"
add-apt-repository --yes ppa:git-core/ppa
# apt-get update
echo -e "\e[34mInstall a lot of packages using apt.\e[0m"
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
  pandoc \
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

# yq
echo -e "\e[34mInstall YQ.\e[0m"
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
add-apt-repository --yes ppa:rmescandon/yq
apt-get update
apt-get install yq -y

# hashicorp vault
wget https://releases.hashicorp.com/vault/1.4.2/vault_1.4.2_linux_amd64.zip -O /tmp/vault.zip
rm -rf /tmp/vault
unzip /tmp/vault.zip -d /tmp/vault
mv /tmp/vault/vault /usr/local/bin/
rm /tmp/vault.zip
rm -rf /tmp/vault

# microsoft repos
echo -e "\e[34mInstall Microsoft repos.\e[0m"
install https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
apt-get update

# dotnet
echo -e "\e[34mInstall .NET cli.\e[0m"
apt-get install -y dotnet-sdk-2.1 dotnet-sdk-3.1

# az
echo -e "\e[34mInstall Az.\e[0m"
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y azure-cli

# kubectl
echo -e "\e[34mInstall Kubectl.\e[0m"
addKey https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
# or curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl


# kubespy
echo -e "\e[34mInstall Kubespy.\e[0m"
wget https://github.com/pulumi/kubespy/releases/download/v0.5.1/kubespy-linux-amd64.tar.gz -O /tmp/kubespy.tar.gz
rm /tmp/kubespy -rf
mkdir -p /tmp/kubespy
tar -xvzf /tmp/kubespy.tar.gz -C /tmp/kubespy/
rm /tmp/kubespy.tar.gz
mv /tmp/kubespy/releases/kubespy-linux-amd64/kubespy /usr/local/bin/
rm /tmp/kubespy -rf

# google chrome
echo -e "\e[34mInstall Google Chrome.\e[0m"
addKey https://dl-ssl.google.com/linux/linux_signing_key.pub
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get install -y google-chrome-stable

# dive
echo -e "\e[34mInstall Dive.\e[0m"
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
    echo -e "\e[34mInstall Docker cli only.\e[0m"
    addKey https://download.docker.com/linux/ubuntu/gpg
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get install -y docker-ce-cli
  fi
else
  echo -e "\e[34mInstall Docker.\e[0m"
  wget -q -O - https://get.docker.com | bash
fi

# helm 3
echo -e "\e[34mInstall Helm 3.\e[0m"
if ! [ -L /usr/local/bin/helm ]; then
  wget -q -O - https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  mv /usr/local/bin/helm /usr/local/bin/helm3
  ln -s /usr/local/bin/helm3 /usr/local/bin/helm
fi

# helm 2
echo -e "\e[34mInstall Helm 2.\e[0m"
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

# chart releaser - cr
echo -e "\e[34mInstall Chart releaser (CR).\e[0m"
wget https://github.com/helm/chart-releaser/releases/download/v1.0.0-beta.1/chart-releaser_1.0.0-beta.1_linux_amd64.tar.gz -O /tmp/cr.tar.gz
rm /tmp/cr -rf
mkdir -p /tmp/cr
tar -xvzf /tmp/cr.tar.gz -C /tmp/cr/
rm /tmp/cr.tar.gz
mv /tmp/cr/cr /usr/local/bin/
rm /tmp/cr -rf

# istioctl
echo -e "\e[34mInstall Istioctl.\e[0m"
wget -q -O - https://istio.io/downloadIstioctl | sh -
mv $HOME/.istioctl/bin/istioctl /usr/local/bin/
rm -rf $HOME/.istioctl

# exa
echo -e "\e[34mInstall Exa.\e[0m"
wget https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip -O /tmp/exa.zip
rm -rf /tmp/exa
unzip /tmp/exa.zip -d /tmp/exa
mv /tmp/exa/exa-linux-x86_64 /usr/local/bin/exa
rm /tmp/exa.zip
rm -rf /tmp/exa

# terraform
echo -e "\e[34mInstall Terraform.\e[0m"
wget https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip -O /tmp/tf.zip
rm -rf /tmp/tf
unzip /tmp/tf.zip -d /tmp/tf
mv /tmp/tf/terraform /usr/local/bin/
rm /tmp/tf.zip
rm -rf /tmp/tf

# terraform lint - tflint
echo -e "\e[34mInstall TFLint.\e[0m"
wget https://github.com/terraform-linters/tflint/releases/download/v0.16.2/tflint_linux_amd64.zip -O /tmp/tflint.zip
rm -rf /tmp/tflint
unzip /tmp/tflint.zip -d /tmp/tflint
sudo mv /tmp/tflint/tflint /usr/local/bin/
rm /tmp/tflint.zip
rm -rf /tmp/tflint

# delta
echo -e "\e[34mInstall Delta.\e[0m"
wget https://github.com/dandavison/delta/releases/download/0.1.1/git-delta_0.1.1_amd64.deb -O /tmp/delta.deb
apt-get install /tmp/delta.deb
rm /tmp/delta.deb

# Github cli
echo -e "\e[34mInstall Github cli.\e[0m"
install https://github.com/cli/cli/releases/download/v0.10.0/gh_0.10.0_linux_amd64.deb

# upgrade
echo -e "\e[34mUpgrade with APT.\e[0m"
apt-get upgrade -y
