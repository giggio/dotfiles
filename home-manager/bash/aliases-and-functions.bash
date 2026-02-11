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

function my/ble-hook/rename-zellij-tab-before {
  if ! [ -v ZELLIJ ]; then
    return
  fi
  local args
  IFS=" " read -ra args <<<"$*"
  local prog_name="${args[0]}"
  set -- "${args[@]}"
  local tab_name="$prog_name"
  shift
  case "$prog_name" in
  less)
    tab_name="<"
    ;;
  nix-* | hm | sm | nr | nix)
    tab_name="󱄅"
    ;;
  bat)
    tab_name="󰭟"
    ;;
  vi | vim | nvim)
    local dir=
    dir="${PWD##*/}"
    tab_name=" $dir"
    ;;
  ssh)
    while [ "$#" -gt 0 ]; do
      case "$1" in
      -*) ;;
      *@*)
        tab_name="⚡ ${1#*@}"
        break
        ;;
      *)
        tab_name="⚡ $1"
        break
        ;;
      esac
      shift
    done
    ;;
  exit)
    return
    ;;
  *) ;;
  esac
  zellij action rename-tab "$tab_name"
}

function my/ble-hook/rename-zellij-tab-after {
  if [ -v ZELLIJ ]; then
    local dir=''
    if [ "$PWD" == "/tmp" ]; then
      dir="🗑️"
    elif [ "$PWD" == "$HOME" ]; then
      dir=🏡
    elif [[ "$PWD" == "$HOME"* ]]; then
      dir="${PWD#"$HOME"}"
      if [ ${#dir} -gt 10 ]; then
        dir="/../${dir##*/}"
      fi
      dir="🏡$dir"
    else
      if [ ${#PWD} -gt 10 ]; then
        dir="/../${PWD##*/}"
      else
        dir="$PWD"
      fi
    fi
    zellij action rename-tab "$dir"
  fi
}

function zellij_cheats() {
  echo "Ctrl Alt Shift t => Tab
Ctrl Shift f => Search
Ctrl Shift g => Lock
Ctrl Shift m => Move
Ctrl Shift n => Resize
Ctrl Shift o => Session
Ctrl Shift p => Pane
Ctrl Shift q => Quit"
}
