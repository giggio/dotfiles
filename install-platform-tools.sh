#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

BASIC_SETUP=false
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
Install platform tools (.NET tools, Npm tools, Pip tools etc).

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
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

if $BASIC_SETUP; then
  exit
fi

# npm tools
export NG_CLI_ANALYTICS=ci
NPM_PKGS_INSTALLED=$(npm ls -g --parseable --depth 0 | tail -n +2 | sed -E "s/$(npm prefix -g | sed 's/\//\\\//g')\/lib\/node_modules\///g" | sort)
NPM_PKGS_TO_INSTALL=`echo "@angular/cli
@githubnext/github-copilot-cli
bash-language-server
bats
bats-assert
bats-support
bower
cross-env
eslint
express-generator
gist-cli
gitignore
glob-tester-cli
grunt-cli
gulp
http-server
karma-cli
license-checker
loadtest
madge
mocha
nodemon
npmrc
pm2
prettier
prettier-plugin-awk
trash-cli
typescript
vtop
yaml-cli" | sort`
# todo: prettier-plugin-awk is causing installation problems, see: https://github.com/Beaglefoot/prettier-plugin-awk/issues/18
NPM_PKGS_NOT_INSTALLED=`comm -23 <(echo "$NPM_PKGS_TO_INSTALL") <(echo "$NPM_PKGS_INSTALLED")`
if [ "$NPM_PKGS_NOT_INSTALLED" != "" ]; then
  # shellcheck disable=SC2086
  writeBlue Install packages $NPM_PKGS_NOT_INSTALLED with npm.
  # shellcheck disable=SC2086
  npm install -g $NPM_PKGS_NOT_INSTALLED
elif $VERBOSE; then
  writeBlue "Not installing Npm packages, they are already installed."
fi
if $UPDATE; then
  if [ "`npm outdated -g`" != '' ]; then
    writeBlue "Updating npm packages."
    npm update -g
  else
    if $VERBOSE; then
      writeBlue "Not installing Npm packages, they are already up to date."
    fi
  fi
fi

# krew tools
if hash krew 2>/dev/null; then
  krew update
  KREW_PLUGINS_INSTALLED=`krew list | tail -n+1 | awk '{print $1}' | sort -u`
  KREW_PLUGINS_TO_INSTALL=`echo "get-all
resource-capacity
sniff
tail" | sort`
  KREW_PLUGINS_NOT_INSTALLED=`comm -23 <(echo "$KREW_PLUGINS_TO_INSTALL") <(echo "$KREW_PLUGINS_INSTALLED")`
  if [ "$KREW_PLUGINS_NOT_INSTALLED" != "" ]; then
    writeBlue "Installing Krew plugins: $KREW_PLUGINS_NOT_INSTALLED"
    # shellcheck disable=SC2086
    krew install $KREW_PLUGINS_NOT_INSTALLED
  elif $VERBOSE; then
    writeBlue "Not installing krew plugins, they are already installed."
  fi
  if $UPDATE; then
    writeBlue "Updating Krew plugins."
    krew upgrade
  fi
else
  writeBlue "Krew not available, skipping..."
fi

if [ -f "$HOME"/.cargo/env ]; then
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  # rust/cargo
  CRATES_INSTALLED=`cargo install --list | cut -f1 -d' ' | awk 'NF'`
  # todo: how to work with as-tree, which is not on crates.io?
  # See issue: https://github.com/jez/as-tree/issues/14
  CRATES_TO_INSTALL=""
  CRATES_TO_INSTALL_NO_LOCK=""
  CRATES_NOT_INSTALLED=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL")) <(sort <(echo "$CRATES_INSTALLED"))`
  if [ "$CRATES_NOT_INSTALLED" != "" ]; then
    writeBlue "Install crates $CRATES_NOT_INSTALLED."
    # shellcheck disable=SC2086
    cargo install --locked $CRATES_NOT_INSTALLED
  else
    if $VERBOSE; then
      writeBlue "Not installing crates, they are already installed."
    fi
  fi
  CRATES_NOT_INSTALLED_NO_LOCK=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL_NO_LOCK")) <(sort <(echo "$CRATES_INSTALLED"))`
  if [ "$CRATES_NOT_INSTALLED_NO_LOCK" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Install crates $CRATES_NOT_INSTALLED_NO_LOCK without --locked.
    # shellcheck disable=SC2086
    cargo install $CRATES_NOT_INSTALLED_NO_LOCK
  else
    if $VERBOSE; then
      writeBlue "Not installing crates without --locked, they are already installed."
    fi
  fi
  if $UPDATE; then
    writeBlue "Updating crates."
    cargo install-update -a
  fi
fi
