# Metrics

Puppet module to setup the metrics component of HySDS.


## Prerequisites
Create a base CentOS7 image as described [here](https://github.com/hysds/hysds-framework/wiki/Puppet-Automation#create-a-base-centos-7-image-for-installation-of-all-hysds-component-instances).


## Installation
As _root_ run:
```
bash < <(curl -skL https://github.com/hysds/puppet-metrics/raw/master/install.sh)
```

## Build Docker images
```
./build_docker.sh <tag>
```
