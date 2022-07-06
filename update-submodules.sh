#!/usr/bin/env bash

set -euo pipefail

git checkout main
git pull --recurse-submodules --ff-only
git submodule update --init --recursive
git submodule foreach 'bash -c "if git branch --no-color | grep main &> /dev/null; then git checkout main; else git checkout master; fi"'
git submodule foreach git pull origin --ff-only
