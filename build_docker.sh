#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Enter tag as arg: $0 <tag>"
  echo "e.g.: $0 20170620"
  echo "e.g.: $0 latest"
  exit 1
fi
TAG=$1


# enable docker buildkit to allow build secrets
export DOCKER_BUILDKIT=1
  

# set oauth token to bypass github API rate limits
OAUTH_CFG="$HOME/.git_oauth_token"
if [ ! -e "$OAUTH_CFG" ]; then
  touch $OAUTH_CFG # create empty creds file for unauthenticated builds
fi
  
  
# build
docker system prune -f || :
docker build --progress=plain --rm --force-rm \
  -t hysds/metrics:${TAG} -f docker/Dockerfile --build-arg RELEASE=${TAG} \
  --secret id=git_oauth_token,src=$OAUTH_CFG . || exit 1
