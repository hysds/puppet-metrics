#!/bin/bash
set -e

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <github org> <branch> <base branch>"
  echo "e.g.: $0 hysds master master"
  echo "e.g.: $0 hysds python2 develop"
  echo "e.g.: $0 pymonger python3 develop"
  exit 1
fi
ORG=$1
BRANCH=$2
BASE_BRANCH=$3

mods_dir=/etc/puppetlabs/code/modules
mkdir -p $mods_dir
cd $mods_dir

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
  echo "Subversion must be installed. Run 'dnf install git'."
  exit 1
fi

puppet_cmd=`which puppet`
if [ $? -ne 0 ]; then
  echo "Puppet must be installed. Run 'dnf install puppet'."
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
# install puppetlab's firewall module
##########################################

mod_dir=$mods_dir/firewall

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $puppet_cmd module install puppetlabs-firewall
fi


##########################################
# export hysds_base puppet module
##########################################

git_loc="${git_url}/${ORG}/puppet-hysds_base"
mod_dir=$mods_dir/hysds_base
site_pp=$mod_dir/site.pp

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $git_cmd clone --single-branch -b $BASE_BRANCH $git_loc $mod_dir
fi


##########################################
# export metrics puppet module
##########################################

git_loc="${git_url}/${ORG}/puppet-metrics"
mod_dir=$mods_dir/metrics
site_pp=$mod_dir/site.pp

# check that module is here; if not, export it
if [ ! -d $mod_dir ]; then
  $git_cmd clone --single-branch -b $BRANCH $git_loc $mod_dir
fi


##########################################
# apply
##########################################

$puppet_cmd apply $site_pp
