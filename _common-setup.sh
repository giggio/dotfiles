if ! (return 0 2>/dev/null); then
  >&2 echo  -e "\e[31mThis script should be sourced.\e[0m"
  exit 1
fi

set -euo pipefail
ALL_ARGS=$@
. $BASEDIR/_functions.sh
getOptions "$@"
eval set -- "$PARSED_ARGS"
