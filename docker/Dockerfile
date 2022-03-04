# syntax = docker/dockerfile:1.0-experimental
ARG TAG=latest
FROM hysds/dev:${TAG}

# get org and branch
ARG ORG
ARG BRANCH
ARG FRAMEWORK_BRANCH
ARG BASE_BRANCH

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/${ORG}/puppet-metrics/raw/${BRANCH}/install.sh

# get release to install
ARG HYSDS_RELEASE=develop

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/${ORG}/puppet-metrics/git/refs/heads/${BRANCH} version.json

# provision via puppet
RUN --mount=type=secret,id=git_oauth_token sudo cp /run/secrets/git_oauth_token $HOME/.git_oauth_token \
 && sudo chown ops:ops $HOME/.git_oauth_token \
 && set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh ${ORG} ${BRANCH} ${BASE_BRANCH} \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum \
 && cd $HOME \
 && ./install_hysds.sh ${FRAMEWORK_BRANCH} ${HYSDS_RELEASE} \
 && rm -rf $HOME/metrics/ops/*/.git* \
 && rm -rf $HOME/.cache \
 && rm -rf $HOME/.git_oauth_token


FROM hysds/base:${TAG}

MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="HySDS metrics images"

# get org and branch
ARG ORG
ARG BRANCH
ARG BASE_BRANCH

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/${ORG}/puppet-metrics/raw/${BRANCH}/install.sh

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh ${ORG} ${BRANCH} ${BASE_BRANCH} \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum

# copy ops home
COPY --chown=ops:ops --from=0 /home/ops /home/ops

# link configs
RUN set -ex \
 && ln -sf /home/ops/metrics/etc/celeryconfig.py /home/ops/metrics/ops/hysds/celeryconfig.py

# set default supervisord conf and copy includes
COPY --chown=ops:ops docker/supervisord.conf /home/ops/metrics/etc/supervisord.conf
COPY --chown=ops:ops docker/conf.d /home/ops/metrics/etc/conf.d

# set entrypoint
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 22 80 443 5601 9001
CMD ["supervisord"]
