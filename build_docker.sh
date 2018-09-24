#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Enter tag as arg: $0 <tag>"
  echo "e.g.: $0 20170620"
  echo "e.g.: $0 latest"
  exit 1
fi
TAG=$1

docker build --no-cache --rm --force-rm -t hysds/metrics:${TAG} -f docker/Dockerfile . || exit 1
