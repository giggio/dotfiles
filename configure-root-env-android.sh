#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh
THIS_FILE="${BASH_SOURCE[0]}"

if (return 0 2> /dev/null); then
  echo "Don't source this script ($THIS_FILE)."
  exit 1
fi

SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help | -h)
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
  cat << EOF
Configures root environment (Android).

Usage:
  $(readlink -f "$0") [flags]

Flags:
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running $(basename "$0") $ALL_ARGS"
fi

if ! $ANDROID; then
  die "This is not running in Android."
fi

# update localhost:
if ! grep -qE '127.0.0.1\s+localhost' /etc/hosts; then
  writeBlue "Host localhost not found in /etc/hosts, adding 127.0.0.1 to it."
  echo -e "127.0.0.1\tlocalhost" >> "/etc/hosts"
fi
if ! grep -qE '::1\s+ip6-localhost\s+ip6-loopback' /etc/hosts; then
  writeBlue "Host ip6-localhost not found in /etc/hosts, adding ::1 to it."
  echo -e "::1\tip6-localhost\tip6-loopback" >> "/etc/hosts"
fi
