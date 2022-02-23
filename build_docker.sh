#!/bin/bash
if [ "$#" -ne 7 ]; then
  echo "Usage: $0 <tag> <github org> <github repo branch> <framework branch> <hysds release> <base image tag> <base branch>"
  echo "e.g.: $0 20170620 hysds master develop v4.0.1-beta.7 latest develop"
  echo "e.g.: $0 latest pymonger develop develop develop develop master"
  exit 1
fi
TAG=$1
ORG=$2
BRANCH=$3
FRAMEWORK_BRANCH=$4
HYSDS_RELEASE=$5
BASE_IMAGE_TAG=$6
BASE_BRANCH=$7


# enable docker buildkit to allow build secrets
export DOCKER_BUILDKIT=1
  

# set oauth token to bypass github API rate limits
OAUTH_CFG="$HOME/.git_oauth_token"
if [ ! -e "$OAUTH_CFG" ]; then
  touch $OAUTH_CFG # create empty creds file for unauthenticated builds
fi
  
  
# build

docker build --progress=plain --rm --force-rm \
  -t hysds/metrics:${TAG} -f docker/Dockerfile \
  --build-arg FRAMEWORK_BRANCH=${FRAMEWORK_BRANCH} \
  --build-arg HYSDS_RELEASE=${HYSDS_RELEASE} \
  --build-arg TAG=${BASE_IMAGE_TAG} \
  --build-arg ORG=${ORG} \
  --build-arg BRANCH=${BRANCH} \
  --build-arg BASE_BRANCH=${BASE_BRANCH} \
  --secret id=git_oauth_token,src=$OAUTH_CFG . || exit 1
docker system prune -f || :
