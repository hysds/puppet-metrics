FROM hysds/dev:python3

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-metrics/raw/docker-python3/install.sh

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-metrics/git/refs/heads/docker-python3 version.json

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum \
 && cd $HOME \
 && ./install_hysds.sh \
 && rm -rf $HOME/metrics/ops/*/.git* \
 && rm -rf $HOME/.cache


FROM hysds/base:python3

MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="HySDS metrics images"

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-metrics/raw/docker-python3/install.sh

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-metrics/git/refs/heads/docker-python3 version.json

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
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
