#!/usr/bin/env bash

set -euo pipefail

# hooks are always ran from the root of the repo

echo "Reformatting nix files..."
pushd system-manager > /dev/null
nix fmt
popd > /dev/null
