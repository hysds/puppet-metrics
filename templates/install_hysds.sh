#!/bin/bash

METRICS_DIR=<%= @metrics_dir %>


## install elasticsearch-head dependencies
#if [ ! -e "$HOME/node/bin/grunt" ]; then
#  cd $HOME/elasticsearch-head
#  npm install
#  cd -
#fi


# create virtualenv if not found
if [ ! -e "$METRICS_DIR/bin/activate" ]; then
  /opt/conda/bin/virtualenv --system-site-packages $METRICS_DIR
  echo "Created virtualenv at $METRICS_DIR."
fi


# source virtualenv
source $METRICS_DIR/bin/activate


# install latest pip and setuptools
pip install -U pip
pip install -U setuptools


# force install supervisor
if [ ! -e "$METRICS_DIR/bin/supervisord" ]; then
  #pip install --ignore-installed supervisor
  pip install --ignore-installed git+https://github.com/Supervisor/supervisor
fi


# create etc directory
if [ ! -d "$METRICS_DIR/etc" ]; then
  mkdir $METRICS_DIR/etc
fi


# create log directory
if [ ! -d "$METRICS_DIR/log" ]; then
  mkdir $METRICS_DIR/log
fi


# create run directory
if [ ! -d "$METRICS_DIR/run" ]; then
  mkdir $METRICS_DIR/run
fi


# set oauth token
OAUTH_CFG="$HOME/.git_oauth_token"
if [ -e "$OAUTH_CFG" ]; then
  source $OAUTH_CFG
  GIT_URL="https://${GIT_OAUTH_TOKEN}@github.com"
else
  GIT_URL="https://github.com"
fi


# create ops directory
OPS="$METRICS_DIR/ops"
if [ ! -d "$OPS" ]; then
  mkdir $OPS
fi


# export latest prov_es package
cd $OPS
PACKAGE=prov_es
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest osaka package
cd $OPS
GITHUB_REPO=osaka
PACKAGE=osaka
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -U pyasn1
pip install -U pyasn1-modules
pip install -U python-dateutil
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds_commons package
cd $OPS
PACKAGE=hysds_commons
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds package
cd $OPS
PACKAGE=hysds
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
pip install -U  greenlet
pip install -U  pytz
pip uninstall -y celery
cd $OPS/$PACKAGE/third_party/celery-v3.1.25.pqueue
pip install -e .
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest sciflo package
cd $OPS
PACKAGE=sciflo
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi
