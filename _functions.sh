if ! (return 0 2>/dev/null); then
  >&2 echo "This script should be sourced."
  exit 1
fi

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
    if [[ `pysemver compare $MAX_TO_MATCH $VERSION_TO_MATCH` == '-1' ]]; then
      MAX=$VERSION
    fi
  done <<< `echo "$1"`
  echo "$MAX"
}

githubLatestReleaseVersion () {
  # parameter expected to be owner/repo
  R=`curl -fsSL https://api.github.com/repos/$1/releases?per_page=100 \
  | jq --raw-output '.[] | select(.prerelease == false).tag_name'`
  getLatestVersion "$R"
}

githubLatestTag () {
  # parameter expected to be owner/repo
  T=`curl -fsSL https://api.github.com/repos/$1/git/matching-refs/tags/?per_page=100 \
  | jq --raw-output '.[].ref' \
  | sed 's/refs\/tags\///'`
  getLatestVersion "$T"
}
