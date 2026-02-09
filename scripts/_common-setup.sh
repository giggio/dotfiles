if ! (return 0 2> /dev/null); then
  >&2 echo -e "\e[31mThis script should be sourced.\e[0m"
  exit 1
fi

set -euo pipefail
# shellcheck disable=SC2034
ALL_ARGS=$*
if ! [ -v SCRIPTSDIR ]; then
  SCRIPTSDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
# shellcheck source=system-manager/etc/profile.d/xdg_dirs_extra.sh
source "$SCRIPTSDIR"/../system-manager/etc/profile.d/xdg_dirs_extra.sh
# shellcheck source=scripts/_functions.sh
source "$SCRIPTSDIR"/_functions.sh
getOptions "$@"
eval set -- "$PARSED_ARGS"

if [ -f /.dockerenv ] || grep docker /proc/1/cgroup -qa 2> /dev/null; then
  export RUNNING_IN_CONTAINER=true
else
  export RUNNING_IN_CONTAINER=false
fi
export DEBIAN_FRONTEND=noninteractive
if grep '[Mm]icrosoft' /proc/version -q &> /dev/null; then
  export WSL=true
else
  export WSL=false
fi
if uname -o | grep Android &> /dev/null; then
  export ANDROID=true
else
  export ANDROID=false
fi
if [ "aarch64" == "$(uname -m)" ]; then
  export ARM=true
else
  export ARM=false
fi
