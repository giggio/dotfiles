#!/usr/bin/env bash

set -euo pipefail

git checkout main
git pull --recurse-submodules --ff-only
git submodule update --init --recursive
git submodule foreach git checkout main
git submodule foreach git pull origin --ff-only
