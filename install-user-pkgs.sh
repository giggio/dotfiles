#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $BASEDIR/_functions.sh

if [ "$EUID" == "0" ]; then
  echo "Please do not run this script as root"
  exit 2
fi

ALL_ARGS=$@
GH_USERNAME_PASSWORD=''
CURL_OPTION_GH_USERNAME_PASSWORD=''
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --gh)
    GH_USERNAME_PASSWORD=$2
    CURL_OPTION_GH_USERNAME_PASSWORD=" --user $2 "
    shift
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
Installs user packages.

Usage:
  `readlink -f $0` [flags]

Flags:
      --gh <user:pw>       GitHub username and password
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

# dvm - deno
if ! hash dvm 2>/dev/null && ! [ -e $HOME/bin/dvm ]; then
  echo -e "\e[34mInstall DVM.\e[0m"
  DVM_TARGZ='dvm_linux_amd64.tar.gz'
  DVM_DL_URL=`githubReleaseDownloadUrl axetroy/dvm $DVM_TARGZ`
  DVM_TMP_DIR='/tmp/dvm'
  mkdir -p $DVM_TMP_DIR
  DVM_TARGZ_TMP="$DVM_TMP_DIR/$DVM_TARGZ"
  curl -fsSL --output $DVM_TARGZ_TMP $DVM_DL_URL
  pushd $DVM_TMP_DIR > /dev/null
  tar -xvzf $DVM_TARGZ_TMP
  mv dvm $HOME/bin/
  popd > /dev/null
  rm -rf $DVM_TMP_DIR
  export PATH=$PATH:$HOME/.deno/bin
  $HOME/bin/dvm install latest
  $HOME/bin/dvm use `$HOME/bin/dvm ls | tail -n1`
elif $UPDATE; then
  dvm upgrade
  if ! dvm ls-remote | grep -q 'Latest and currently using'; then
    dvm install latest
    dvm use `dvm ls | tail -n1`
  fi
fi

# rbenv
if ! [ -f $BASEDIR/tools/rbenv/shims/ruby ]; then
  echo -e "\e[34mInstall ruby-build and install Ruby with rbenv.\e[0m"
  git clone https://github.com/rbenv/ruby-build.git $BASEDIR/tools/rbenv/plugins/ruby-build
  $HOME/.rbenv/bin/rbenv install 2.7.6
  $HOME/.rbenv/bin/rbenv install 3.1.2
  $HOME/.rbenv/bin/rbenv global 3.1.2
elif $VERBOSE; then
  echo "Not installing Rbenv and generating Ruby, it is already installed."
fi

# rust
if ! [ -x $HOME/.cargo/bin/rustc ]; then
  curl -fsSL https://sh.rustup.rs | bash -s -- -y --no-modify-path
  $HOME/.cargo/bin/rustup toolchain install {stable,beta,nightly}
elif $UPDATE; then
  $HOME/.cargo/bin/rustup update
fi

# tfenv
if ! $HOME/bin/tfenv list &> /dev/null; then
  echo -e "\e[34mInstall Tfenv.\e[0m"
  $BASEDIR/tools/tfenv/bin/tfenv install latest:^0.12.
  $BASEDIR/tools/tfenv/bin/tfenv install latest:^0.13.
  $BASEDIR/tools/tfenv/bin/tfenv install latest
  $BASEDIR/tools/tfenv/bin/tfenv use latest
elif $UPDATE; then
  LATEST_TFENV=`getLatestVersion $($BASEDIR/tools/tfenv/bin/tfenv list-remote | grep --color=never -v '-')`
  LATEST_012=`getLatestVersion $($BASEDIR/tools/tfenv/bin/tfenv list-remote | grep --color=never -v '-' | grep --color=never '^0.12')`
  LATEST_013=`getLatestVersion $($BASEDIR/tools/tfenv/bin/tfenv list-remote | grep --color=never -v '-' | grep --color=never '^0.13')`
  CURRENT_012=`$BASEDIR/tools/tfenv/bin/tfenv list | sed -E 's/\*//' | awk '{print $1}' | grep --color=never '^0.12'`
  CURRENT_013=`$BASEDIR/tools/tfenv/bin/tfenv list | sed -E 's/\*//' | awk '{print $1}' | grep --color=never '^0.13'`
  echo -e "\e[34mUpdate Tfenv.\e[0m"
  if [ "$LATEST_012" != "$CURRENT_012" ]; then
    $BASEDIR/tools/tfenv/bin/tfenv uninstall $CURRENT_012
    $BASEDIR/tools/tfenv/bin/tfenv install latest:^0.12.
  fi
  if [ "$LATEST_013" != "$CURRENT_013" ]; then
    $BASEDIR/tools/tfenv/bin/tfenv uninstall $CURRENT_013
    $BASEDIR/tools/tfenv/bin/tfenv install latest:^0.13.
  fi
  if ! $BASEDIR/tools/tfenv/bin/tfenv list | sed -E 's/\*//' | awk '{print $1}' | grep --color=never -q $LATEST_TFENV; then
    $BASEDIR/tools/tfenv/bin/tfenv install latest
    $BASEDIR/tools/tfenv/bin/tfenv use latest
  fi
fi

# krew
if ! hash kubectl-krew 2>/dev/null && ! [ -e $HOME/.krew/bin/kubectl-krew ]; then
  echo -e "\e[34mInstall krew.\e[0m"
  curl -fsSL --output /tmp/krew.tar.gz https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz
  rm -rf /tmp/krew/
  mkdir /tmp/krew/
  tar -xvzf /tmp/krew.tar.gz -C /tmp/krew/
  /tmp/krew/krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" install krew
  rm -rf /tmp/krew/
  rm /tmp/krew.tar.gz
elif $UPDATE; then
  VERSION=`githubLatestReleaseVersion kubernetes-sigs/krew`
  CURRENT_VERSION=`kubectl krew version | grep GitTag | awk '{print $2}'`
  kubectl krew upgrade
elif $VERBOSE; then
  echo "Not installing Krew, it is already installed."
fi

# docker-show-context
if ! hash docker-show-context 2>/dev/null && ! [ -e $HOME/bin/docker-show-context ]; then
  echo -e "\e[34mInstall docker-show-context.\e[0m"
  curl -fsSL --output $HOME/bin/docker-show-context https://github.com/pwaller/docker-show-context/releases/latest/download/docker-show-context_linux_amd64
  chmod +x $HOME/bin/docker-show-context
elif $VERBOSE; then
  echo "Not installing docker-show-context, it is already installed."
fi

# golang
GO_ARCH=''
case `uname -m` in
  x86_64)
    GO_ARCH=amd64
    ;;
  aarch64)
    GO_ARCH=arm64
    ;;
  armv7l)
    GO_ARCH=armv6l
    ;;
  *)
    echo "Golang will not be installed: unsupported architecture: `uname -m`"
    ;;
esac
if [ "$GO_ARCH" != '' ]; then
  installGolang () {
    curl -fsSL --output /tmp/go.tar.gz https://go.dev/dl/go$GO_AVAILABLE_VERSION.linux-$GO_ARCH.tar.gz
    rm -rf $HOME/.go/
    tar -C /tmp/ -xzvf /tmp/go.tar.gz go/bin go/pkg go/lib go/src
    mv /tmp/go $HOME/.go
    rm /tmp/go.tar.gz
  }
  GO_AVAILABLE_VERSION=`githubLatestTagByDate golang/go go1. | \
  sed 's/refs\/tags\/go//'`
  if ! hash go  2>/dev/null && ! [ -d $HOME/.go/ ] &> /dev/null; then
    echo -e "\e[34mInstall golang.\e[0m"
    installGolang
  elif $UPDATE; then
    GO_CURRENT_VERSION=`go version 2>/dev/null | sed -E 's/^.*go([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+).*$/\1/'`
    if [ "$GO_AVAILABLE_VERSION" != "$GO_CURRENT_VERSION" ]; then
      echo -e "\e[34mUpdate golang.\e[0m"
      installGolang
    elif $VERBOSE; then
      echo "Not updating golang, it is already up to date."
    fi
  elif $VERBOSE; then
    echo "Not installing golang, it is already installed."
  fi
fi

#fzf
if ! [ -e $HOME/.fzf/bin/fzf ] || $UPDATE; then
  $HOME/.fzf/install --no-update-rc --no-completion --no-key-bindings --no-bash
fi

# docker-slim
ARCH=''
case `uname -m` in
  x86_64)
    ARCH=linux
    ;;
  aarch64)
    ARCH=linux_arm64
    ;;
  armv7l)
    ARCH=linux_arm
    ;;
  *)
    echo "Docker-slim will not be installed: unsupported architecture: `uname -m`"
    ;;
esac
if ! hash docker-slim 2>/dev/null && ! [ -e $HOME/bin/docker-slim ]; then
  echo -e "\e[34mInstall docker-slim.\e[0m"
  DSLIMTAR=/tmp/docker-slim.tar.gz
  DS_VERSION=`githubLatestTagByVersion docker-slim/docker-slim`
  curl -fsSL --output $DSLIMTAR https://downloads.dockerslim.com/releases/$DS_VERSION/dist_$ARCH.tar.gz
  mkdir /tmp/dslim/
  tar -xvzf $DSLIMTAR -C /tmp/dslim/
  mv /tmp/dslim/dist_linux/* $HOME/bin/
  rm -rf /tmp/dslim/
  rm $DSLIMTAR
elif $UPDATE; then
  DS_CURRENT_VERSION=`docker-slim --version | cut -d'|' -f3`
  DS_AVAILABLE_VERSION=`githubLatestTagByVersion docker-slim/docker-slim`
  if [ "$DS_AVAILABLE_VERSION" != "$DS_CURRENT_VERSION" ]; then
    echo -e "\e[34mUpdate docker-slim.\e[0m"
    docker-slim update
  elif $VERBOSE; then
    echo "Not updating docker-slim, already up to date."
  fi
elif $VERBOSE; then
  echo "Not installing docker-slim, it is already installed."
fi
