#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILESDIR=/home/user/.dotfiles
docker run -ti --name dft \
  -v $BASEDIR/configure-user-env.sh:$DOTFILESDIR/configure-user-env.sh \
  -v $BASEDIR/configure-root-env.sh:$DOTFILESDIR/configure-root-env.sh \
  -v $BASEDIR/install:$DOTFILESDIR/install \
  -v $BASEDIR/install.sh:$DOTFILESDIR/install.sh \
  -v $BASEDIR/install-root-pkgs.sh:$DOTFILESDIR/install-root-pkgs.sh \
  -v $BASEDIR/install-user-pkgs.sh:$DOTFILESDIR/install-user-pkgs.sh \
  -v $BASEDIR/install-platform-tools.sh:$DOTFILESDIR/install-platform-tools.sh \
  -v $BASEDIR/install.conf.yaml:$DOTFILESDIR/install.conf.yaml \
  -v $BASEDIR/pre-install.sh:$DOTFILESDIR/pre-install.sh \
  -v $BASEDIR/post-install.sh:$DOTFILESDIR/post-install.sh \
  dft
