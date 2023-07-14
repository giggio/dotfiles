#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $BASEDIR/_common-setup.sh

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
  `readlink -f $0` [flags]

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
if [[ "`gpg --list-keys $keyId 2> /dev/null | grep ^uid | grep [ultimate]`" == '' ]]; then
  gpgPublicKeyFile=`mktemp`
  gpgOwnerTrustFile=`mktemp`
  curl -fsSL https://links.giggio.net/pgp --output $gpgPublicKeyFile
  echo "$keyId:6:" > $gpgOwnerTrustFile
  gpg --import $gpgPublicKeyFile
  gpg --import-ownertrust $gpgOwnerTrustFile
  rm $gpgPublicKeyFile
  rm $gpgOwnerTrustFile
fi
