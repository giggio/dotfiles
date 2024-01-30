if ! (return 0 2>/dev/null); then
  >&2 echo  -e "\e[31mThis script should be sourced.\e[0m"
  exit 1
fi

FUNCTIONS_ARGS=("$@")
CURL=curl
while [[ $# -gt 0 ]]; do
  case "$1" in
    --curl)
    CURL=$2
    shift
    shift
    ;;
    *)
    shift
    ;;
  esac
done
set -- "${FUNCTIONS_ARGS[@]}"
unset FUNCTIONS_ARGS

getLatestVersion() {
  local max=0.0.0
  while read -r version; do
    if [ "$version" == '' ]; then
      continue
    fi
    version_to_match=`normalizeVersion "$version"`
    max_to_match=`normalizeVersion "$max"`
    if [[ `pysemver compare "$max_to_match" "$version_to_match" 2> /dev/null` == '-1' ]]; then
      max=$version
    fi
  done <<< "$1"
  echo "$max"
}

# call like this: versionGreater 1.2.4 1.2.3
# exit code is 0 if first version is greater than second version, otherwise it is 1
versionGreater() {
  local v1
  v1=`normalizeVersion "$1"`
  local v2
  v2=`normalizeVersion "$2"`
  if [ "`pysemver compare "$v1" "$v2" 2> /dev/null`" == '1' ]; then
    return 0
  fi
  return 1
}

# call like this: versionSmaller 1.2.4 1.2.3
# exit code is 0 if first version is smaller than second version, otherwise it is 1
versionSmaller() {
  versionGreater "$2" "$1"
  return $?
}

# call like this: versionsEqual 1.2.4 1.2.3
# exit code is 0 if versions are equal, otherwise it is 1
versionsEqual() {
  # not comparing with == directly because 8.0.1+123 is equal to 8.0.1, but not string equals
  local v1
  v1=`normalizeVersion "$1"`
  local v2
  v2=`normalizeVersion "$2"`
  if [ "`pysemver compare "$v1" "$v2" 2> /dev/null`" == '0' ]; then
    return 0
  fi
  return 1
}

versionsDifferent () {
  ! versionsEqual "$1" "$2"
}

# normalizes version to 1.2.3
# if version is 1 then it will be normalized to 1.0.0
# if version is 1.2 then it will be normalized to 1.2.0
# if version is v1.2.3 then the 'v' will be removed and it will be normalized to 1.2.3
# if empty string is passed then empty string is returned
normalizeVersion() {
  local version=$1
  if [ "$version" == '' ]; then
    echo "$version"
    return
  fi
  if [[ "$version" == v* ]]; then
    version="${version:1}"
  fi
  if [[ "$version" =~ ^[[:digit:]]+\.[[:digit:]]+$ ]]; then
    version="$version.0"
  elif [[ "$version" =~ ^[[:digit:]]+$ ]]; then
    version="$version.0.0"
  fi
  echo "$version"
}

githubLatestReleaseVersion () {
  # parameter expected to be owner/repo
  R=`githubAllReleasesVersions "$1"`
  # todo: grep for stable? like:
  # grep -E '^(?P<major>0|[1-9][0-9]*)\.(?P<minor>0|[1-9][0-9]*)\.(?P<patch>0|[1-9][0-9]*)$'
  # see: https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
  getLatestVersion "$R"
}

githubAllReleasesVersions () {
  # parameter expected to be owner/repo
  # shellcheck disable=SC2086
  curl -fsSL "${CURL_GH_HEADERS[@]}" https://api.github.com/repos/$1/releases?per_page=50 \
  | jq --raw-output '.[] | select(.prerelease == false).tag_name'
}

githubTags () {
  # parameter expected to be owner/repo
  # shellcheck disable=SC2086
  curl -fsSL "${CURL_GH_HEADERS[@]}" https://api.github.com/repos/$1/git/matching-refs/tags/?per_page=50 \
  | jq --raw-output '.[].ref' \
  | sed 's/^refs\/tags\///'
}

githubLatestTagByVersion () {
  # parameter expected to be owner/repo
  getLatestVersion "`githubTags "$1"`"
}

githubReleaseDownloadUrl () {
  local REPO=$1
  local NAME_FILTER=''
  if [ -v 2 ]; then
    if [[ "$2" =~ ^\|.* ]]; then
      NAME_FILTER="$2"
    else
      NAME_FILTER='|test("'"$2"'")'
    fi
  fi
  local url
  # shellcheck disable=SC2086
  url=$($CURL -fsSL "${CURL_GH_HEADERS[@]}" https://api.github.com/repos/$REPO/releases | \
    jq --raw-output "[.[] | select(.prerelease == false)][0].assets[] | select(.name$NAME_FILTER).browser_download_url")
  if [ -z "$url" ]; then
    local name_filter_message=''
    if [ -v 2 ]; then
      name_filter_message="and name filter $2"
    fi
    error "Could not find download url for $REPO $name_filter_message (calling 'githubReleaseDownloadUrl $*')"
    return 1
  fi
  echo "$url"
}

githubLatestTagByDate () {
  local REPO=$1
  local TAG_FILTER=''
  if [ -v 2 ]; then
    TAG_FILTER="$2"
  fi
  # shellcheck disable=SC2086
  $CURL -fsSL "${CURL_GH_HEADERS[@]}" https://api.github.com/repos/$REPO/git/matching-refs/tags/$TAG_FILTER | jq --raw-output '.[-1].ref'
}

checkIfNeedsGitPull () {
  UPSTREAM=${1:-'@{u}'}
  LOCAL=`git rev-parse @`
  REMOTE=`git rev-parse "$UPSTREAM"`
  BASE=`git merge-base @ "$UPSTREAM"`
  if [ "$LOCAL" = "$REMOTE" ]; then
    # up to date
    return 1
  elif [ "$LOCAL" = "$BASE" ]; then
    return 0
  elif [ "$REMOTE" = "$BASE" ]; then
    # Needs to push, so no
    return 1
  fi
  # Diverged, so no
  return 1
}

installDeb () {
  DEB=$1
  DEB="${DEB##*/}" # get file name
  DEB="${DEB%%\?*}" # remove query string
  DEB="${DEB%%\#*}" # remove fragment
  DEB=/tmp/$DEB
  curl -fsSL --output "$DEB" "$1"
  apt-get install "$DEB"
  rm "$DEB"
}

# use it like this:
# installBinToDir /path/to/dir `githubReleaseDownloadUrl owner/repo linux-amd64`
# or
# installBinToDir /path/to/dir `githubReleaseDownloadUrl owner/repo linux-amd64` bin-name
installBinToDir () {
  if ! [ -d "$1" ]; then
    mkdir -p "$1"
  fi
  if [ -v 3 ]; then
    BIN=$1/$3
  else
    BIN=$2
    BIN="${BIN##*/}" # get file name
    BIN="${BIN%%\?*}" # remove query string
    BIN="${BIN%%\#*}" # remove fragment
    BIN=$1/$BIN
  fi
  curl -fsSL --output "$BIN" "$2"
  chmod +x "$BIN"
}

# use it like this: installBinToHomeBin `githubReleaseDownloadUrl owner/repo linux-amd64`
installBinToHomeBin () {
  installBinToDir "$HOME/bin" "$@"
}

# use it like this: installBinToUsrLocalBin "`githubReleaseDownloadUrl knative/client kn-linux-amd64`" kn
installBinToUsrLocalBin () {
  if [ -v 2 ]; then
    BIN=/usr/local/bin/$2
  else
    BIN=$1
    BIN="${BIN##*/}" # get file name
    BIN="${BIN%%\?*}" # remove query string
    BIN="${BIN%%\#*}" # remove fragment
    BIN=/usr/local/bin/$BIN
  fi
  rm -f "$BIN"
  curl -fsSL --output "$BIN" "$1"
  chmod +x "$BIN"
}

# use it like this:
# installTarToDir /path/to/dir/ "`githubReleaseDownloadUrl dotnet/cli-lab`" path/in/tar/dotnet-core-uninstall dotnet-core-uninstall
# or
# installTarToDir /path/to/dir/ "`githubReleaseDownloadUrl dotnet/cli-lab`"
# first parameter is directory
# second parameter is url,
# third parameter is optional and is the file path inside tar file, if not supplied all files in tar will placed in the directory,
# fourth parameter is optional and is the executable name - if not supplied it will be inferred from the second parameter
installTarToDir () {
  local TAR_FILE_NAME=$2
  TAR_FILE_NAME="${TAR_FILE_NAME##*/}" # get file name
  TAR_FILE_NAME="${TAR_FILE_NAME%%\?*}" # remove query string
  TAR_FILE_NAME="${TAR_FILE_NAME%%\#*}" # remove fragment
  if ! [ -d "$1" ]; then
    mkdir -p "$1"
  fi
  if [ -v 4 ]; then
    local BIN=$1/$4
  elif [ -v 3 ]; then
    local BIN=$3
    BIN="${BIN##*/}"
    BIN=$1/$BIN
  fi
  rm -f "/tmp/$TAR_FILE_NAME"
  curl -fsSL --output "/tmp/$TAR_FILE_NAME" "$2"
  if [ -v BIN ]; then
    tar --overwrite -xzf "/tmp/$TAR_FILE_NAME" -C /tmp "$3"
    mv "/tmp/$3" "$BIN"
  else
    tar --overwrite -xzf "/tmp/$TAR_FILE_NAME" -C "$1"
  fi
  rm "/tmp/$TAR_FILE_NAME"
}

# use it like this: installTarToUsrLocalBin "`githubReleaseDownloadUrl dotnet/cli-lab`" path/in/tar/dotnet-core-uninstall dotnet-core-uninstall
# first parameter is url,
# second parameter is file path inside tar file,
# third parameter is optional and is the executable name - if not supplied it will be inferred from the second parameter
installTarToUsrLocalBin () {
  installTarToDir /usr/local/bin "$@"
}

# use it like this: installTarToHomeBin "`githubReleaseDownloadUrl owner/repo`" path/in/tar/binary-name executable-name
# first parameter is url,
# second parameter is file path inside tar file,
# third parameter is optional and is the executable name - if not supplied it will be inferred from the second parameter
installTarToHomeBin () {
  installTarToDir "$HOME"/bin "$@"
}

addSourceListAndKey () {
  local KEYRING_URL=$1
  local LIST_INFO=$2
  local LIST_FILE=$3
  if [ -v 4 ]; then
    local KEYRING_FILE=$4
  else
    local KEYRING_FILE=$LIST_FILE-keyring.gpg
  fi
  addKey "$KEYRING_URL" "$KEYRING_FILE"
  addSourcesList "$LIST_INFO" "$LIST_FILE" "$KEYRING_FILE"
}

addKey () {
  local KEYRING_URL=$1
  if [[ "$2" == *-keyring.gpg ]]; then
    local KEYRING_FILE=$2
  else
    local KEYRING_FILE=$2-keyring.gpg
  fi
  local KEYRING_TMP_FILE=/tmp/$KEYRING_FILE
  KEYRING_FILE=/etc/apt/trusted.gpg.d/$KEYRING_FILE
  curl -fsSL --output "$KEYRING_TMP_FILE" "$KEYRING_URL"
  if [ "`file --mime-type -b "$KEYRING_TMP_FILE"`" == 'application/pgp-keys' ]; then
    writeBlue "Converting $KEYRING_TMP_FILE to $KEYRING_FILE with gpg --dearmor"
    < "$KEYRING_TMP_FILE" gpg --dearmor > "$KEYRING_FILE"
    rm "$KEYRING_TMP_FILE"
  else
    writeBlue "Saving gpg key to $KEYRING_FILE"
    mv "$KEYRING_TMP_FILE" "$KEYRING_FILE"
  fi
}

addSourcesList () {
  local LIST_INFO=$1
  local LIST_FILE=$2
  if [ -v 3 ]; then
    if [[ "$3" == *-keyring.gpg ]]; then
      local KEYRING_FILE=$3
    else
      local KEYRING_FILE=$3-keyring.gpg
    fi
  else
    local KEYRING_FILE=$LIST_FILE-keyring.gpg
  fi
  KEYRING_FILE=/etc/apt/trusted.gpg.d/$KEYRING_FILE
  LIST_FILE_CONTENTS="deb [arch=`dpkg --print-architecture` signed-by=$KEYRING_FILE] $LIST_INFO"
  if [ ! -f "/etc/apt/sources.list.d/$LIST_FILE.list" ] || [ "`cat /etc/apt/sources.list.d/"$LIST_FILE".list`" != "$LIST_FILE_CONTENTS" ]; then
    writeBlue "Creating or updating file '/etc/apt/sources.list.d/$LIST_FILE.list' with value: '$LIST_FILE_CONTENTS'"
    echo "$LIST_FILE_CONTENTS" > /etc/apt/sources.list.d/"$LIST_FILE".list
    apt-get update
  elif $VERBOSE; then
    writeBlue "Not creating file '/etc/apt/sources.list.d/$LIST_FILE.list', it already exists and has the correct value."
  fi
}

function installAlternative() {
  local name=$1
  local bin_path=$2
  local exec_path=$3
  if ! update-alternatives --query "$name" &>/dev/null; then
    writeBlue "Creating alternative for $name ($bin_path) and setting the default value to $exec_path."
    update-alternatives --install "$bin_path" "$name" "$exec_path" 1
    update-alternatives --set "$name" "$exec_path"
  else
    if ! update-alternatives --query "$name" | grep -q "Alternative:\s$exec_path" &> /dev/null; then
      writeBlue "Creating alternative for $name ($bin_path) as $exec_path."
      local last_priority
      last_priority=`update-alternatives --query "$name" | awk '/Priority:\s([[:digit:]]+)/ { print $2 }' | sort | tail -n 1`
      ((++last_priority))
      writeBlue "Priority of $exec_path will be $last_priority."
      update-alternatives --install "$bin_path" "$name" "$exec_path" "$last_priority"
    elif $VERBOSE; then
      writeBlue "Not Adding alternative $exec_path to $name ($bin_path), it is already present."
    fi
    if ! update-alternatives --query "$name" | grep -q "Value:\s$exec_path"; then
      writeBlue "Setting value of alternative of $name ($bin_path) to $exec_path."
      update-alternatives --set "$name" "$exec_path"
    elif $VERBOSE; then
      writeBlue "Not setting value of alternative of $name ($bin_path) to $exec_path, it is already set."
    fi
  fi
}

function setAlternative() {
  NAME=$1
  EXEC_PATH=`which "$2"`
  if [ "`update-alternatives --display "$NAME" | sed -n 's/.*link currently points to \(.*\)$/\1/p'`" != "$EXEC_PATH" ]; then
    update-alternatives --set "$NAME" "$EXEC_PATH"
  else
    if $VERBOSE; then
      writeBlue "Not updating alternative to $NAME, it is already set."
    fi
  fi
}

dump_stack () {
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
  ( set -o posix ; set )
}

getOptions () {
  # shellcheck disable=SC2034
  PARSED_ARGS=`getopt -o bscuh --long basic,gh:,clean,update,help,verbose,quick,skip-post-install -n "$(readlink -f "$0")" -- "$@"`
}

writeYellow () {
  echo -e "\e[33m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

writeBlue () {
  echo -e "\e[34m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

writeGreen () {
  echo -e "\e[32m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

writeStdErrRed () {
  >&2 echo -e "\e[31m`date +'%Y-%m-%dT%H:%M:%S'`: $*\e[0m"
}

error () {
  writeStdErrRed "$@"
  return 1
}

die () {
  writeStdErrRed "$@"
  exit 1
}
