#!/bin/bash
set -e

# set HOME explicitly
export HOME=/home/ops

# wait for redis and ES
/wait-for-it.sh -t 30 metrics-redis:6379
/wait-for-it.sh -t 60 metrics-elasticsearch:9200

# get group id
GID=$(id -g)

# generate ssh keys
gosu 0:0 ssh-keygen -A 2>/dev/null

# update user and group ids
gosu 0:0 groupmod -g $GID ops 2>/dev/null
gosu 0:0 usermod -u $UID -g $GID ops 2>/dev/null
gosu 0:0 usermod -aG docker ops 2>/dev/null

# update ownership
gosu 0:0 chown -R $UID:$GID $HOME 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/log/supervisor 2>/dev/null || true

# source bash profile
source $HOME/.bash_profile

# source metrics virtualenv
if [ -e "$HOME/metrics/bin/activate" ]; then
  source $HOME/metrics/bin/activate
fi

# install kibana metrics
#if [ -e "/tmp/import_dashboards.sh" ]; then
#  /tmp/import_dashboards.sh
#fi

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
