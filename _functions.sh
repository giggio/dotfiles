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
  local MAX=0.0.0
  while read VERSION; do
    if [ "$VERSION" == '' ]; then
      continue
    fi
    if [[ "$VERSION" == v* ]]; then
      VERSION="${VERSION:1}"
    fi
    VERSION_TO_MATCH="$VERSION"
    MAX_TO_MATCH="$MAX"
    if [[ "$VERSION" =~ ^[[:digit:]]+\.[[:digit:]]+$ ]]; then
      VERSION_TO_MATCH="$VERSION.0"
    elif [[ "$VERSION" =~ ^[[:digit:]]+$ ]]; then
      VERSION_TO_MATCH="$VERSION.0.0"
    fi
    if [[ "$MAX" =~ ^[[:digit:]]+\.[[:digit:]]+$ ]]; then
      MAX_TO_MATCH="$MAX.0"
    elif [[ "$MAX" =~ ^[[:digit:]]+$ ]]; then
      MAX_TO_MATCH="$MAX.0.0"
    fi
    if [[ `pysemver compare $MAX_TO_MATCH $VERSION_TO_MATCH 2> /dev/null` == '-1' ]]; then
      MAX=$VERSION
    fi
  done <<< `echo "$1"`
  echo "$MAX"
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
  curl -fsSL $CURL_OPTION_GH_USERNAME_PASSWORD https://api.github.com/repos/$1/releases?per_page=100 \
  | jq --raw-output '.[] | select(.prerelease == false).tag_name'
}

githubTags () {
  # parameter expected to be owner/repo
  # shellcheck disable=SC2086
  curl -fsSL $CURL_OPTION_GH_USERNAME_PASSWORD https://api.github.com/repos/$1/git/matching-refs/tags/?per_page=100 \
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
  # shellcheck disable=SC2086
  $CURL -fsSL $CURL_OPTION_GH_USERNAME_PASSWORD https://api.github.com/repos/$REPO/releases | \
  jq --raw-output "[.[] | select(.prerelease == false)][0].assets[] | select(.name$NAME_FILTER).browser_download_url"
}

githubLatestTagByDate () {
  local REPO=$1
  local TAG_FILTER=''
  if [ -v 2 ]; then
    TAG_FILTER="$2"
  fi
  # shellcheck disable=SC2086
  $CURL -fsSL $CURL_OPTION_GH_USERNAME_PASSWORD https://api.github.com/repos/$REPO/git/matching-refs/tags/$TAG_FILTER | jq --raw-output '.[-1].ref'
}

checkIfNeedsGitPull () {
  UPSTREAM=${1:-'@{u}'}
  LOCAL=`git rev-parse @`
  REMOTE=`git rev-parse "$UPSTREAM"`
  BASE=`git merge-base @ "$UPSTREAM"`
  if [ "$LOCAL" = "$REMOTE" ]; then
    # up to date
    echo 'false'
  elif [ "$LOCAL" = "$BASE" ]; then
    echo 'true'
  elif [ "$REMOTE" = "$BASE" ]; then
    # Needs to push, so no
    echo 'false'
  else
    # Diverged, so no
    echo 'false'
  fi
}

versionsEqual () {
  V1=`echo "$1" | sed 's/^v//'`
  V2=`echo "$2" | sed 's/^v//'`
  [ "$V1" == "$V2" ]
}

versionsDifferent () {
  ! versionsEqual "$1" "$2"
}

installDeb () {
  DEB=$1
  DEB=`echo "${DEB##*/}"` # get file name
  DEB=`echo "${DEB%%\?*}"` # remove query string
  DEB=`echo "${DEB%%\#*}"` # remove fragment
  DEB=/tmp/$DEB
  curl -fsSL --output $DEB $1
  apt-get install $DEB
  rm $DEB
}

installBinToHomeBin () {
  if [ -v 2 ]; then
    BIN=$HOME/bin/$2
  else
    BIN=$1
    BIN=`echo "${BIN##*/}"` # get file name
    BIN=`echo "${BIN%%\?*}"` # remove query string
    BIN=`echo "${BIN%%\#*}"` # remove fragment
    BIN=$HOME/bin/$BIN
  fi
  curl -fsSL --output "$BIN" "$1"
  chmod +x "$BIN"
}

# use it like this: installBinToUsrLocalBin "`githubReleaseDownloadUrl knative/client kn-linux-amd64`" kn
installBinToUsrLocalBin () {
  if [ -v 2 ]; then
    BIN=/usr/local/bin/$2
  else
    BIN=$1
    BIN=`echo "${BIN##*/}"` # get file name
    BIN=`echo "${BIN%%\?*}"` # remove query string
    BIN=`echo "${BIN%%\#*}"` # remove fragment
    BIN=/usr/local/bin/$BIN
  fi
  rm -f "$BIN"
  curl -fsSL --output "$BIN" "$1"
  chmod +x "$BIN"
}

# use it like this: installTarToUsrLocalBin "`githubReleaseDownloadUrl dotnet/cli-lab`" path/in/tar/dotnet-core-uninstall dotnet-core-uninstall
# first parameter is url,
# second parameter is file path inside tar file,
# third parameter is optional and is the executable name - if not supplied it will be inferred from the second parameter
installTarToUsrLocalBin () {
  TAR_FILE_NAME=$1
  TAR_FILE_NAME="${TAR_FILE_NAME##*/}" # get file name
  TAR_FILE_NAME="${TAR_FILE_NAME%%\?*}" # remove query string
  TAR_FILE_NAME="${TAR_FILE_NAME%%\#*}" # remove fragment
  if [ -v 3 ]; then
    BIN=/usr/local/bin/$3
  else
    BIN=$2
    BIN="${BIN##*/}"
    BIN=/usr/local/bin/$BIN
  fi
  rm -f "/tmp/$TAR_FILE_NAME"
  curl -fsSL --output "/tmp/$TAR_FILE_NAME" "$1"
  rm -rf "/tmp/$TAR_FILE_NAME.dir"
  mkdir -p "/tmp/$TAR_FILE_NAME.dir"
  tar -xzf "/tmp/$TAR_FILE_NAME" -C "/tmp/$TAR_FILE_NAME.dir/" "$2"
  rm -f "$BIN"
  mv "/tmp/$TAR_FILE_NAME.dir/$2" "$BIN"
  rm "/tmp/$TAR_FILE_NAME"
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
  curl -fsSL --output $KEYRING_TMP_FILE $KEYRING_URL
  if [ `file --mime-type -b $KEYRING_TMP_FILE` == 'application/pgp-keys' ]; then
    writeBlue "Converting $KEYRING_TMP_FILE to $KEYRING_FILE with gpg --dearmor"
    cat $KEYRING_TMP_FILE | gpg --dearmor > $KEYRING_FILE
    rm $KEYRING_TMP_FILE
  else
    writeBlue "Saving gpg key to $KEYRING_FILE"
    mv $KEYRING_TMP_FILE $KEYRING_FILE
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
  if [ ! -f "/etc/apt/sources.list.d/$LIST_FILE.list" ] || [ "`cat /etc/apt/sources.list.d/$LIST_FILE.list`" != "$LIST_FILE_CONTENTS" ]; then
    writeBlue "Creating or updating file '/etc/apt/sources.list.d/$LIST_FILE.list' with value: '$LIST_FILE_CONTENTS'"
    echo "$LIST_FILE_CONTENTS" > /etc/apt/sources.list.d/$LIST_FILE.list
    apt-get update
  elif $VERBOSE; then
    writeBlue "Not creating file '/etc/apt/sources.list.d/$LIST_FILE.list', it already exists and has the correct value."
  fi
}

dumpStack () {
    local i=0
    local line_no
    local function_name
    local file_name
    while caller $i; do
      ((i++))
    done | while read line_no function_name file_name; do
      echo -e "\t$file_name:$line_no\t$function_name"
    done >&2
}

showVars() {
  ( set -o posix ; set )
}

getOptions () {
  PARSED_ARGS=`getopt -o cuh --long gh:,clean,update,help,verbose,quick,skip-post-install -n $(readlink -f $0) -- "$@"`
}

writeBlue () {
  echo  -e "\e[34m`date +'%Y-%m-%dT%H:%M:%S'`: $@\e[0m"
}

writeGreen () {
  echo  -e "\e[32m`date +'%Y-%m-%dT%H:%M:%S'`: $@\e[0m"
}

writeStdErrRed () {
  >&2 echo  -e "\e[31m`date +'%Y-%m-%dT%H:%M:%S'`: $@\e[0m"
}

die () {
  writeStdErrRed "$@"
  exit 1
}
