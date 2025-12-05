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

# override hub browse to allow for other git forges
git() {
  if [ "$1" = "browse" ]; then
    local remote
    remote="$(git remote -v | grep origin | grep fetch | awk '{print $2}')"
    if [ -z "$remote" ]; then
      command hub "$@"
    elif [[ $remote == http://* || $remote = https://* ]]; then
      xdg-open "$remote"
    elif [[ $remote == ssh://git@codeberg.org/* ]]; then # ssh://git@codeberg.org/owner/repo.git
      xdg-open "https://codeberg.org/${remote#ssh://git@codeberg.org/}"
    elif [[ $remote == git@gitlab.com:* ]]; then # git@gitlab.com:owner/repo.git
      xdg-open "https://gitlab.com/${remote#git@gitlab.com:}"
    elif [[ $remote == git@github.com:* ]]; then # git@github.com:owner/repo.git
      xdg-open "https://github.com/${remote#git@github.com:}"
    else
      echo "Unknown remote: $remote, submit a new request to https://github.com/giggio/dotfiles"
    fi
  else
    command hub "$@"
  fi
}
