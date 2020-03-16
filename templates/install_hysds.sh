#!/bin/bash
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)


# usage
usage() {
  echo "usage: $0 <release tag>" >&2
}


# check usage
if [ $# -ne 1 ]; then
  usage
  exit 1
fi
release=$1


# print out commands and exit on any errors
set -e

# set oauth token
OAUTH_CFG="$HOME/.git_oauth_token"
if [ -e "$OAUTH_CFG" ]; then
  source $OAUTH_CFG
fi
if [ -z "${GIT_OAUTH_TOKEN}" ]; then
  GIT_URL="https://github.com"
  token=""
else
  GIT_URL="https://${GIT_OAUTH_TOKEN}@github.com"
  token=" -k ${GIT_OAUTH_TOKEN} "
fi


# clone hysds-framework
cd $HOME
PACKAGE=hysds-framework
if [ ! -d "$HOME/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $HOME/$PACKAGE
if [ "$release" = "develop-es7" ]; then
  git checkout $release
  ./install.sh -d $token metrics
else
  ./install.sh -r $release $token metrics
fi


METRICS_DIR=<%= @metrics_dir %>


# source virtualenv
source $METRICS_DIR/bin/activate


# cleanup pkgs
rm -rf $METRICS_DIR/pkgs/*
