#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" == "0" ]; then
  echo "Please do not run this script as root"
  exit 2
fi

ALL_ARGS=$@
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
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
if ! hash dvm 2>/dev/null; then
  DVM_TARGZ='dvm_linux_amd64.tar.gz'
  DVM_DL_URL=`curl -fsSL https://api.github.com/repos/axetroy/dvm/releases | \
  jq --raw-output '[.[] | select(.prerelease == false)][0].assets[] | select(.name|test("'$DVM_TARGZ'")).browser_download_url'`
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
  dvm install latest
  dvm use `dvm ls | tail -n1`
fi

# rbenv
if ! [ -f $BASEDIR/tools/rbenv/shims/ruby ]; then
  echo -e "\e[34mInstall ruby-build and install Ruby with rbenv.\e[0m"
  git clone https://github.com/rbenv/ruby-build.git $BASEDIR/tools/rbenv/plugins/ruby-build
  $HOME/.rbenv/bin/rbenv install 2.7.6
  $HOME/.rbenv/bin/rbenv install 3.1.2
  $HOME/.rbenv/bin/rbenv global 3.1.2
else
  if $VERBOSE; then
    echo "Not installing Rbenv and generating Ruby, it is already installed."
  fi
fi

# rust
if ! [ -x $HOME/.cargo/bin/rustc ]; then
  curl -fsSL https://sh.rustup.rs | bash -s -- -y --no-modify-path
  $HOME/.cargo/bin/rustup toolchain install {stable,beta,nightly}
elif $UPDATE; then
  $HOME/.cargo/bin/rustup update
fi

# tfenv
if ! $HOME/bin/tfenv list &> /dev/null || $UPDATE; then
  $BASEDIR/tools/tfenv/bin/tfenv install latest:^0.12.
  $BASEDIR/tools/tfenv/bin/tfenv install latest:^0.13.
  $BASEDIR/tools/tfenv/bin/tfenv install latest
  $BASEDIR/tools/tfenv/bin/tfenv use latest
fi

# krew
if ! hash krew 2>/dev/null; then
  echo -e "\e[34mInstall krew.\e[0m"
  wget https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz -O /tmp/krew.tar.gz
  rm -rf /tmp/krew/
  mkdir /tmp/krew/
  tar -xvzf /tmp/krew.tar.gz -C /tmp/krew/
  /tmp/krew/krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" install krew
  rm -rf /tmp/krew/
  rm /tmp/krew.tar.gz
elif $UPDATE; then
  kubectl krew upgrade
else
  if $VERBOSE; then
    echo "Not installing Krew, it is already installed."
  fi
fi

# docker-show-context
if ! hash docker-show-context 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall docker-show-context.\e[0m"
  curl -fsSL --output $HOME/bin/docker-show-context https://github.com/pwaller/docker-show-context/releases/latest/download/docker-show-context_linux_amd64
  chmod +x $HOME/bin/docker-show-context
else
  if $VERBOSE; then
    echo "Not installing docker-show-context, it is already installed."
  fi
fi

# golang
if ! hash go &> /dev/null; then
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
    GO_VERSION=`curl -fsSL https://api.github.com/repos/golang/go/git/matching-refs/tags/go1. | \
    jq --raw-output '.[-1].ref' | \
    sed 's/refs\/tags\/go//'`
    curl -fsSL --output /tmp/go.tar.gz https://go.dev/dl/go$GO_VERSION.linux-$GO_ARCH.tar.gz
    rm -rf $HOME/.go/
    tar -C /tmp/ -xzvf /tmp/go.tar.gz go/bin go/pkg go/lib go/src
    mv /tmp/go $HOME/.go
    rm /tmp/go.tar.gz
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
if ! hash docker-slim 2>/dev/null; then
  echo -e "\e[34mInstall docker-slim.\e[0m"
  DSLIMTAR=/tmp/docker-slim.tar.gz
  DS_VERSION=`curl -fsSL https://api.github.com/repos/docker-slim/docker-slim/git/matching-refs/tags/1. | \
  jq --raw-output '.[-1].ref' | \
  sed 's/refs\/tags\///'`
  curl -fsSL --output $DSLIMTAR https://downloads.dockerslim.com/releases/$DS_VERSION/dist_$ARCH.tar.gz
  mkdir /tmp/dslim/
  tar -xvzf $DSLIMTAR -C /tmp/dslim/
  mv /tmp/dslim/dist_linux/* $HOME/bin/
  rm -rf /tmp/dslim/
  rm $DSLIMTAR
elif $UPDATE; then
  docker-slim update
else
  if $VERBOSE; then
    echo "Not installing docker-slim, it is already installed."
  fi
fi
