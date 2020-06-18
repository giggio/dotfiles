#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILESDIR=/home/user/.dotfiles
docker run -ti --name dft \
  -v $BASEDIR/install:$DOTFILESDIR/install \
  -v $BASEDIR/install.sh:$DOTFILESDIR/install.sh \
  -v $BASEDIR/install-pkgs.sh:$DOTFILESDIR/install-pkgs.sh \
  -v $BASEDIR/install.conf.yaml:$DOTFILESDIR/install.conf.yaml \
  -v $BASEDIR/pre-install.sh:$DOTFILESDIR/pre-install.sh \
  -v $BASEDIR/post-install.sh:$DOTFILESDIR/post-install.sh \
  dft
