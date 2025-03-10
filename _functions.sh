if ! (return 0 2> /dev/null); then
  echo -e "\e[31mThis script should be sourced.\e[0m" >&2
  exit 1
fi

FUNCTIONS_ARGS=("$@")
while [[ $# -gt 0 ]]; do
  case "$1" in
    *)
      shift
      ;;
  esac
done
set -- "${FUNCTIONS_ARGS[@]}"
unset FUNCTIONS_ARGS

function setAlternative() {
  if $VERBOSE; then
    writeBlue "Updating alternative to $1, setting it to $2."
  fi
  NAME=$1
  EXEC_PATH=$(which "$2")
  if [ "$(update-alternatives --display "$NAME" | sed -n 's/.*link currently points to \(.*\)$/\1/p')" != "$EXEC_PATH" ]; then
    update-alternatives --set "$NAME" "$EXEC_PATH"
  else
    if $VERBOSE; then
      writeBlue "Not updating alternative to $NAME, it is already set."
    fi
  fi
}

dump_stack() {
  local i=0
  local line_no
  local function_name
  local file_name
  while caller $i; do
    ((i++))
  done | while read -r line_no function_name file_name; do
    echo -e "\t$file_name:$line_no\t$function_name"
  done >&2
}

showVars() {
  (
    set -o posix
    set
  )
}

getOptions() {
  # shellcheck disable=SC2034
  PARSED_ARGS=$(getopt -o bscuh --long basic,gh:,clean,update,help,verbose,quick,skip-post-install -n "$(readlink -f "$0")" -- "$@")
}

writeYellow() {
  echo -e "\e[33m$(date +'%Y-%m-%dT%H:%M:%S'): $*\e[0m"
}

writeBlue() {
  echo -e "\e[34m$(date +'%Y-%m-%dT%H:%M:%S'): $*\e[0m"
}

writeGreen() {
  echo -e "\e[32m$(date +'%Y-%m-%dT%H:%M:%S'): $*\e[0m"
}

writeStdErrRed() {
  echo -e "\e[31m$(date +'%Y-%m-%dT%H:%M:%S'): $*\e[0m" >&2
}

error() {
  writeStdErrRed "$@"
  return 1
}

die() {
  writeStdErrRed "$@"
  exit 1
}
