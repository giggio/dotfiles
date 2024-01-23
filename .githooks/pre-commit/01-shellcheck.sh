#!/usr/bin/env bash

set -euo pipefail

submodule_dirs=$(git submodule | awk '{ printf "-not -path '"`pwd`"'/" $2 "/* " }')
set -f # disable globbing
# shellcheck disable=SC2086
files=$(find "$(pwd)" -name '*.sh' $submodule_dirs)
# shellcheck disable=SC2086
shellcheck --shell bash $files
set +f
