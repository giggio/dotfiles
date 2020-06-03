#!/usr/bin/env bash

# find current script directory, following symlinks:
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# Path to the bash it configuration
export BASH_IT="$DIR/bash-it"

# Lock and Load a custom theme file, location /.bash_it/themes/
export BASH_IT_THEME=powerline-multiline

# Don't check mail when opening terminal.
unset MAILCHECK

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

# Load Bash It
export BASH_IT_CUSTOM="$DIR/bashscripts/"
source "$BASH_IT/bash_it.sh"
source "$BASH_IT_CUSTOM/bash-it-customizations.sh"
