#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $BASEDIR/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

CURL_OPTION_GH_USERNAME_PASSWORD=''
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gh)
    CURL_OPTION_GH_USERNAME_PASSWORD=" -H 'Authorization: token $2' "
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
eval set -- "$PARSED_ARGS"

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
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE"
fi

# dvm - deno
if ! hash dvm 2>/dev/null && ! [ -e $HOME/bin/dvm ]; then
  writeBlue "Install DVM."
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
  writeBlue "Install ruby-build and install Ruby with rbenv."
  git clone https://github.com/rbenv/ruby-build.git $BASEDIR/tools/rbenv/plugins/ruby-build
  $HOME/.rbenv/bin/rbenv install 2.7.6
  $HOME/.rbenv/bin/rbenv install 3.1.2
  $HOME/.rbenv/bin/rbenv global 3.1.2
elif $VERBOSE; then
  writeBlue "Not installing Rbenv and generating Ruby, it is already installed."
fi

# rust
if ! [ -x $HOME/.cargo/bin/rustc ]; then
  writeBlue "Install Rust tools."
  curl -fsSL https://sh.rustup.rs | bash -s -- -y --no-modify-path
  $HOME/.cargo/bin/rustup toolchain install {stable,beta,nightly}
elif $UPDATE; then
  writeBlue "Update Rust tools."
  $HOME/.cargo/bin/rustup update
elif $VERBOSE; then
  writeBlue "Not installing Rust tools, it is already installed."
fi

# tfenv
if ! $HOME/bin/tfenv list &> /dev/null; then
  writeBlue "Install Tfenv."
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
  writeBlue "Update Tfenv."
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
elif $VERBOSE; then
  writeBlue "Not installing Tfenv, it is already installed."
fi

# krew
if ! hash kubectl-krew 2>/dev/null && ! [ -e $HOME/.krew/bin/kubectl-krew ]; then
  writeBlue "Install krew."
  curl -fsSL --output /tmp/krew.tar.gz https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz
  rm -rf /tmp/krew/
  mkdir /tmp/krew/
  tar -xvzf /tmp/krew.tar.gz -C /tmp/krew/
  /tmp/krew/krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" install krew
  rm -rf /tmp/krew/
  rm /tmp/krew.tar.gz
elif $UPDATE; then
  writeBlue "Update krew."
  kubectl krew upgrade
elif $VERBOSE; then
  writeBlue "Not installing Krew, it is already installed."
fi

# docker-show-context
if ! hash docker-show-context 2>/dev/null && ! [ -e $HOME/bin/docker-show-context ]; then
  writeBlue "Install docker-show-context."
  curl -fsSL --output $HOME/bin/docker-show-context https://github.com/pwaller/docker-show-context/releases/latest/download/docker-show-context_linux_amd64
  chmod +x $HOME/bin/docker-show-context
elif $VERBOSE; then
  writeBlue "Not installing docker-show-context, it is already installed."
fi

# ctop
installCtop () {
  CTOP_DL_URL=`githubReleaseDownloadUrl bcicen/ctop linux-amd64`
  installBinToHomeBin "$CTOP_DL_URL" ctop
}
if ! hash ctop 2>/dev/null; then
  writeBlue "Install Ctop."
  installCtop
elif $UPDATE; then
  CTOP_LATEST_VERSION=`githubLatestReleaseVersion bcicen/ctop`
  if versionsDifferent  "`ctop -v | sed -E 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/g'`" "$CTOP_LATEST_VERSION"; then
    writeBlue "Update Ctop."
    installCtop
  elif $VERBOSE; then
    writeBlue "Not updating Ctop, it is already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not intalling Ctop, it is already installed."
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
    writeBlue "Golang will not be installed: unsupported architecture: `uname -m`"
    ;;
esac
if [ "$GO_ARCH" != '' ]; then
  installGolang () {
    curl -fsSL --output /tmp/go.tar.gz https://go.dev/dl/go$GO_AVAILABLE_VERSION.linux-$GO_ARCH.tar.gz
    rm -rf $HOME/.go/
    tar -C /tmp/ -xzvf /tmp/go.tar.gz go/bin go/pkg go/lib go/src go/go.env
    mv /tmp/go $HOME/.go
    rm /tmp/go.tar.gz
  }
  GO_TAGS=`githubTags golang/go | sed 's/^go//'`
  GO_AVAILABLE_VERSION=`getLatestVersion "$GO_TAGS"`
  if ! hash go  2>/dev/null && ! [ -d $HOME/.go/ ] &> /dev/null; then
    writeBlue "Install golang."
    installGolang
  elif $UPDATE; then
    GO_CURRENT_VERSION=`go version 2>/dev/null | sed -E 's/^.*go([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+).*$/\1/'`
    if [ "$GO_AVAILABLE_VERSION" != "$GO_CURRENT_VERSION" ]; then
      writeBlue "Update golang."
      installGolang
    elif $VERBOSE; then
      writeBlue "Not updating golang, it is already up to date."
    fi
  elif $VERBOSE; then
    writeBlue "Not installing golang, it is already installed."
  fi
fi

#fzf
if ! [ -e $HOME/.fzf/bin/fzf ] || $UPDATE; then
  writeBlue "Install/update fzf."
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
    writeBlue "Docker-slim will not be installed: unsupported architecture: `uname -m`"
    ;;
esac
if ! hash docker-slim 2>/dev/null && ! [ -e $HOME/bin/docker-slim ]; then
  writeBlue "Install docker-slim."
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
    writeBlue "Update docker-slim."
    docker-slim update
  elif $VERBOSE; then
    writeBlue "Not updating docker-slim, already up to date."
  fi
elif $VERBOSE; then
  writeBlue "Not installing docker-slim, it is already installed."
fi

# bin
if ! hash bin 2>/dev/null; then
  writeBlue "Install Bin."
  BIN_DL_URL=`githubReleaseDownloadUrl marcosnils/bin linux_amd64`
  curl -fsSL --output /tmp/bin "$BIN_DL_URL"
  chmod +x /tmp/bin
  mkdir -p "$HOME"/.config/bin/
  echo '{ "default_path": "'"$HOME"'/bin", "bins": { } }' > "$HOME"/.config/bin/config.json
  /tmp/bin install github.com/marcosnils/bin
  rm /tmp/bin
elif $UPDATE; then
  writeBlue "Update Bin."
  bin update bin --yes
elif $VERBOSE; then
  writeBlue "Not installing Bin, it is already installed."
fi
