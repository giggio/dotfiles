#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ]; then
  die "Please do not run this script as root"
fi

SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
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
Configures user environment.

Usage:
  `readlink -f "$0"` [flags]

Flags:
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS"
fi

keyId=275F6749AFD2379D1033548C1237AB122E6F4761
if [[ `gpg --list-keys $keyId 2> /dev/null` == '' ]] || gpg --list-keys $keyId 2> /dev/null | grep ^uid | grep -qs '\[ultimate\]'; then
  gpgPublicKeyFile=`mktemp`
  curl -fsSL https://links.giggio.net/pgp --output "$gpgPublicKeyFile"
  gpgOwnerTrustFile=`mktemp`
  echo "$keyId:6:" > "$gpgOwnerTrustFile"
  gpg --import "$gpgPublicKeyFile"
  gpg --import-ownertrust "$gpgOwnerTrustFile"
  rm "$gpgPublicKeyFile"
  rm "$gpgOwnerTrustFile"
fi

if hash carapace 2>/dev/null && ! [ -f "$HOME"/.config/carapace/schema.json ]; then
  if $VERBOSE; then
    writeBlue "Setting up carapace schema."
  fi
  carapace _carapace > /dev/null
fi

if $WSL; then
  if $VERBOSE; then
    writeBlue "Setting xdg-mime defaults to wslview."
  fi
  xdg-mime default wslview.desktop text/html
  xdg-mime default wslview.desktop x-scheme-handler/http
  xdg-mime default wslview.desktop x-scheme-handler/https
else
  "$BASEDIR"/manage-dconf.sh --import "$@"
fi
