#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" == "0" ]; then
  echo "Please do not run as root"
  exit 2
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTBOT_DIR="$BASEDIR/dotbot"

echo -e "\e[34mUpdating dotbot submodules.\e[0m"
pushd "$DOTBOT_DIR" > /dev/null
git submodule update --init --recursive
popd > /dev/null

echo -e "\e[34mWorking on unpriviledged setup.\e[0m"
"$DOTBOT_DIR/bin/dotbot" -d "${BASEDIR}" -c "$BASEDIR/install.conf.yaml" "${@}"
