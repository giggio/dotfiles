#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh
THIS_FILE="${BASH_SOURCE[0]}"

if [ "$EUID" != '0' ]; then
  die "Please run this script as root"
fi
if (return 0 2>/dev/null); then
  echo "Don't source this script ($THIS_FILE)."
  exit 1
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
Configures root environment (WSL).

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

WSL_CONF=/etc/wsl.conf
# WSL_CONF=/tmp/wsl.conf

isSetup=$(python3 << EOF
import configparser
config = configparser.ConfigParser(allow_no_value=True)
config.read('$WSL_CONF')
print(config.has_option('boot', 'systemd') and config.has_option('automount', 'options'))
EOF
)

if [ "$isSetup" == "True" ]; then
  writeBlue "WSL is already configured, revisiting..."
else
  writeBlue "This is a new WSL configuration..."
fi

if ! [ -f $WSL_CONF ]; then
  touch $WSL_CONF
fi

python3 << EOF
import configparser
config = configparser.ConfigParser(comment_prefixes='/', allow_no_value=True)
config.optionxform = lambda option: option
config.read('$WSL_CONF')

if not config.has_section('boot'):
  config.add_section('boot')
if not config.has_option('boot', 'systemd') or config['boot']['systemd'] != 'true':
  config['boot']['systemd'] = 'true'
  config.write(open('$WSL_CONF', 'w'))

if not config.has_section('automount'):
  config.add_section('automount')
if not config.has_option('automount', 'options') or config['automount']['options'] != '"metadata,umask=22,fmask=11"':
  config['automount']['options'] = '"metadata,umask=22,fmask=11"'
  config.write(open('$WSL_CONF', 'w'))

if not config.has_section('interop'):
  config.add_section('interop')
if not config.has_option('interop', 'appendWindowsPath') or config['interop']['appendWindowsPath'] != 'false':
  config['interop']['appendWindowsPath'] = 'false'
  config.write(open('$WSL_CONF', 'w'))

EOF
