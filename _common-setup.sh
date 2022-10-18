if ! (return 0 2>/dev/null); then
  >&2 echo "This script should be sourced."
  exit 1
fi

set -euo pipefail
ALL_ARGS=$@
. $BASEDIR/_functions.sh
getOptions "$@"
eval set -- "$PARSED_ARGS"
