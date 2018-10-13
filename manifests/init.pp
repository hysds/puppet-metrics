#####################################################
# metrics class
#####################################################

class metrics inherits hysds_base {

  #####################################################
  # copy user files
  #####################################################
  
  file { "/home/$user/.bash_profile":
    ensure  => present,
    content => template('metrics/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => 0644,
    require => User[$user],
  }


  #####################################################
  # metrics directory
  #####################################################

  $metrics_dir = "/home/$user/metrics"


  #####################################################
  # install packages
  #####################################################

  package {
    'mailx': ensure => present;
    'httpd': ensure => present;
    'mod_ssl': ensure => present;
    'npm': ensure => present;
  }


  #####################################################
  # systemd daemon reload
  #####################################################

  exec { "daemon-reload":
    path        => ["/sbin", "/bin", "/usr/bin"],
    command     => "systemctl daemon-reload",
    refreshonly => true,
  }


  #####################################################
  # install oracle java and set default
  #####################################################

  $jdk_rpm_file = "jdk-8u181-linux-x64.rpm"
  $jdk_rpm_path = "/etc/puppet/modules/metrics/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8"
  $jdk_pkg_dir = "jdk1.8.0_181-amd64"
  $java_bin_path = "/usr/java/$jdk_pkg_dir/jre/bin/java"


  cat_split_file { "$jdk_rpm_file":
    install_dir => "/etc/puppet/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { "$jdk_pkg_name":
    provider => rpm,
    ensure   => present,
    source   => $jdk_rpm_path,
    notify   => Exec['ldconfig'],
    require     => Cat_split_file["$jdk_rpm_file"],
  }


  update_alternatives { 'java':
    path     => $java_bin_path,
    require  => [
                 Package[$jdk_pkg_name],
                 Exec['ldconfig']
                ],
  }


  #####################################################
  # get integer memory size in MB
  #####################################################

  if '.' in $::memorysize_mb {
    $ms = split("$::memorysize_mb", '[.]')
    $msize_mb = $ms[0]
  }
  else {
    $msize_mb = $::memorysize_mb
  }


   #####################################################
   # elasticsearch user/password
   #####################################################
 
   $es_user = "elastic"
   $es_password = "elastic"


  #####################################################
  # install install_hysds.sh script and other config
  # files in ops home
  #####################################################

  file { "/home/$user/install_hysds.sh":
    ensure  => present,
    content => template('metrics/install_hysds.sh'),
    owner   => $user,
    group   => $group,
    mode    => 0755,
    require => User[$user],
  }


  file { ["$metrics_dir",
          "$metrics_dir/bin",
          "$metrics_dir/src",
          "$metrics_dir/etc",
          "$metrics_dir/log",
          "$metrics_dir/run"]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    require => User[$user],
  }


  file { "$metrics_dir/bin/metricsd":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('metrics/metricsd'),
    require => File["$metrics_dir/bin"],
  }


  file { "$metrics_dir/bin/start_metrics":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('metrics/start_metrics'),
    require => File["$metrics_dir/bin"],
  }
 

  file { "$metrics_dir/bin/stop_metrics":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('metrics/stop_metrics'),
    require => File["$metrics_dir/bin"],
  }


  cat_split_file { "logstash-6.3.1.tar.gz":
    install_dir => "/etc/puppet/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "logstash-6.3.1.tar.gz":
    install_dir => "/home/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Cat_split_file["logstash-6.3.1.tar.gz"],
               ]
  }


  file { "/home/$user/logstash":
    ensure => 'link',
    target => "/home/$user/logstash-6.3.1",
    owner => $user,
    group => $group,
    require => Tarball['logstash-6.3.1.tar.gz'],
  }


  file { "$metrics_dir/etc/indexer.conf":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0644,
    content => template('metrics/indexer.conf'),
    require => File["/home/$user/logstash"],
  }


  cat_split_file { "kibana-6.3.1-linux-x86_64.tar.gz":
    install_dir => "/etc/puppet/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "kibana-6.3.1-linux-x86_64.tar.gz":
    install_dir => "/home/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Cat_split_file["kibana-6.3.1-linux-x86_64.tar.gz"],
               ]
  }

 
  file { "/home/$user/kibana":
    ensure => 'link',
    target => "/home/$user/kibana-6.3.1-linux-x86_64",
    owner => $user,
    group => $group,
    require => Tarball['kibana-6.3.1-linux-x86_64.tar.gz'],
  }


  file { "/home/$user/kibana/config/kibana.yml":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0644,
    content => template('metrics/kibana.yml'),
    require => File["/home/$user/kibana"],
  }


  #####################################################
  # write rc.local to startup & shutdown metrics
  #####################################################

  file { '/etc/rc.d/rc.local':
    ensure  => file,
    content  => template('metrics/rc.local'),
    mode    => 0755,
  }


  #####################################################
  # secure and start httpd
  #####################################################

  file { "/etc/httpd/conf.d/autoindex.conf":
    ensure  => present,
    content => template('metrics/autoindex.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => present,
    content => template('metrics/welcome.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }

 
  file { "/etc/httpd/conf.d/ssl.conf":
    ensure  => present,
    content => template('metrics/ssl.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }

 
  file { '/var/www/html/index.html':
    ensure  => file,
    content => template('metrics/index.html'),
    mode    => 0644,
    require => Package['httpd'],
  }


  #####################################################
  # install job and worker kibana configs
  #####################################################

  file { "/tmp/worker_metrics.json":
    ensure  => present,
    content => template('metrics/worker_metrics.json'),
    mode    => 0644,
  }


  file { "/tmp/job_metrics.json":
    ensure  => present,
    content => template('metrics/job_metrics.json'),
    mode    => 0644,
  }


  file { "/wait-for-it.sh":
    ensure  => present,
    content => template('metrics/wait-for-it.sh'),
    owner   => $user,
    group   => $group,
    mode    => 0755,
  }


  file { "/tmp/import_dashboards.sh":
    ensure  => present,
    content => template('metrics/import_dashboards.sh'),
    owner   => $user,
    group   => $group,
    mode    => 0755,
  }


}
