#!/bin/bash

mods_dir=/etc/puppet/modules
cd $mods_dir

###############################################################################
# IMPORTANT: please edit this branch name to the version of the Azure         #
#            adaptation that you want to install on every Puppet module       #
###############################################################################
git_branch="azure"


##########################################
# need to be root
##########################################

id=`whoami`
if [ "$id" != "root" ]; then
  echo "You must be root to run this script."
  exit 1
fi


##########################################
# check that puppet and git is installed
##########################################

git_cmd=`which git`
if [ $? -ne 0 ]; then
  echo "Subversion must be installed. Run 'yum install git'."
  exit 1
fi

puppet_cmd=`which puppet`
if [ $? -ne 0 ]; then
  echo "Puppet must be installed. Run 'yum install puppet'."
  exit 1
fi

if [ ! -d "/usr/share/puppet/modules/firewalld" ]; then
  echo "puppet-firewalld must be installed. Run 'yum install puppet-firewalld'."
  exit 1
fi


##########################################
# set git url
##########################################

git_url="https://github.com"


##########################################
# install puppetlab's stdlib module
##########################################

mod_dir=$mods_dir/stdlib

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $puppet_cmd module install puppetlabs-stdlib
fi


##########################################
# export scientific_python puppet module
##########################################

git_loc="${git_url}/hysds/puppet-scientific_python"
mod_dir=$mods_dir/scientific_python
site_pp=$mod_dir/site.pp

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $git_cmd clone -b $git_branch --single-branch $git_loc $mod_dir
fi


##########################################
# export cloud_utils puppet module
##########################################

git_loc="${git_url}/hysds/puppet-cloud_utils"
mod_dir=$mods_dir/cloud_utils
site_pp=$mod_dir/site.pp

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $git_cmd clone -b $git_branch --single-branch $git_loc $mod_dir
fi


##########################################
# export metrics puppet module
##########################################

git_loc="${git_url}/hysds/puppet-metrics"
mod_dir=$mods_dir/metrics
site_pp=$mod_dir/site.pp

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $git_cmd clone -b $git_branch --single-branch $git_loc $mod_dir
fi


##########################################
# apply
##########################################

FACTER_git_oauth_token=$GIT_OAUTH_TOKEN $puppet_cmd apply $site_pp
