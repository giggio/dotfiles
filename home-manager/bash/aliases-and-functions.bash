# allows to use docker build with Containerfile
docker() {
  if [ "$1" = build ]; then
    shift
    has_file_arg=false
    for arg in "$@"; do
      case "$arg" in
      -f | --file) has_file_arg=true ;;
      esac
    done
    if [ "$has_file_arg" = false ]; then
      command docker build -f Containerfile "$@"
    else
      command docker build "$@"
    fi
  else
    command docker "$@"
  fi
}
