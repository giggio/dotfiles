if ! (return 0 2>/dev/null); then
  >&2 echo  -e "\e[31mThis script should be sourced.\e[0m"
  exit 1
fi

set -euo pipefail
# shellcheck disable=SC2034
ALL_ARGS=$*
source "$BASEDIR"/_functions.sh
getOptions "$@"
eval set -- "$PARSED_ARGS"

if [ -f "$HOME"/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
  set +u
  # shellcheck source=/dev/null
  source "$HOME"/.nix-profile/etc/profile.d/hm-session-vars.sh
  set -u
fi
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
if uname -a | grep android &> /dev/null; then
  export ANDROID=true
else
  export ANDROID=false
fi
