# allows to use docker build with Containerfile
docker() {
  if [ "$1" = build ] && [ -f Containerfile ]; then
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
  make)
    tab_name=" $1"
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
    zellij action rename-tab "$dir" --tab-id "$(zellij action list-panes --json | jq -r "map(select(.id == $ZELLIJ_PANE_ID and .is_plugin == false))[0].tab_id")"
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

function ocr {
  if ! [ -v 1 ]; then
    echo "Call this with the image file path, e.g.: 'ocr file.jpg'" >&2
    exit 1
  fi
  if ! [ -f "$1" ]; then
    echo "File $1 does not exist." >&2
    exit 1
  fi
  tesseract -l por "$1" /tmp/t &>/dev/null && cat /tmp/t.txt && cat /tmp/t.txt | clip && rm /tmp/t.txt
}

function add {
  if ! [ -v 1 ]; then
    git add :/
    return
  fi
  git add "$@"
}

function hasBinary {
  hash "$1" 2>/dev/null
}

function hasBinaryInLinux {
  if ! $WSL; then
    hasBinary "$1"
    return
  fi
  PATH=$(removeWindowsFromPath) hash "$1" 2>/dev/null
}

function man {
  case "$(type -t -- "$1")" in
  builtin | keyword)
    help -m "$1" | less
    ;;
  *)
    command man "$@"
    ;;
  esac
}

function edit-var {
  declare -n VAR=$1
  if ! [ -v VAR ]; then
    echo "Variable with name '${!VAR}' does not exist."
    return
  fi
  local TMP
  TMP=$(mktemp)
  echo "${VAR}" >"$TMP"
  vim "$TMP"
  eval "${!VAR}"'=`cat '"$TMP"'`'
  rm "$TMP"
}

function lorem {
  if [ -z "$1" ]; then
    PARAGRAPHS=10
  else
    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
      echo "Usage: lorem <number of paragraphs>"
      return
    fi
    PARAGRAPHS=$1
  fi
  perl -e 'use Text::Lorem;my $text = Text::Lorem->new();$paragraphs = $text->paragraphs('"$PARAGRAPHS"');print $paragraphs;'
}

function watchrun {
  while inotifywait -q -e close_write "$1"; do
    # shellcheck disable=SC2091
    $(realpath "$1")
  done
}
