#####################################################
# metrics class
#####################################################

class metrics inherits scientific_python {

  #####################################################
  # add swap file - DISABLED
  #####################################################

  #swap { '/mnt/swapfile':
  #  ensure   => present,
  #}


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
    'httpd-devel': ensure => present;
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

  $jdk_rpm_file = "jdk-8u241-linux-x64.rpm"
  $jdk_rpm_path = "/etc/puppet/modules/metrics/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8.x86_64"
  $java_bin_path = "/usr/java/jdk1.8.0_241-amd64/jre/bin/java"


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
  # install elasticsearch
  #####################################################

  $es_heap_size = $msize_mb / 2
  $es_rpm_file = "elasticsearch-7.9.3-x86_64.rpm"
  $es_rpm_path = "/etc/puppet/modules/metrics/files/$es_rpm_file"

  cat_split_file { "$es_rpm_file":
    install_dir => "/etc/puppet/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { 'elasticsearch':
    provider => rpm,
    ensure   => present,
    source   => $es_rpm_path,
    require  => [
                  Cat_split_file["$es_rpm_file"],
                  Exec['set-java'],
                ],
  }


  file { '/etc/sysconfig/elasticsearch':
    ensure       => file,
    content      => template('metrics/elasticsearch'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure       => file,
    content      => template('metrics/elasticsearch.yml'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/log4j2.properties':
    ensure       => file,
    content      => template('metrics/log4j2.properties'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/jvm.options':
    ensure       => file,
    content      => template('metrics/jvm.options'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/usr/lib/systemd/system/elasticsearch.service':
    ensure       => file,
    content      => template('metrics/elasticsearch.service'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  service { 'elasticsearch':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/sysconfig/elasticsearch'],
                   File['/etc/elasticsearch/elasticsearch.yml'],
                   File['/etc/elasticsearch/log4j2.properties'],
                   File['/etc/elasticsearch/jvm.options'],
                   File['/usr/lib/systemd/system/elasticsearch.service'],
                   Exec['daemon-reload'],
                  ],
  }


  #####################################################
  # disable transparent hugepages for redis
  #####################################################

  file { "/etc/tuned/no-thp":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/tuned/no-thp/tuned.conf":
    ensure  => present,
    content => template('metrics/tuned.conf'),
    mode    => 0644,
    require => File["/etc/tuned/no-thp"],
  }

  
  exec { "no-thp":
    unless  => "grep -q -e '^no-thp$' /etc/tuned/active_profile",
    path    => ["/sbin", "/bin", "/usr/bin"],
    command => "tuned-adm profile no-thp",
    require => File["/etc/tuned/no-thp/tuned.conf"],
  }


  #####################################################
  # tune kernel for high performance
  #####################################################

  file { "/usr/lib/sysctl.d":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/usr/lib/sysctl.d/metrics.conf":
    ensure  => present,
    content => template('metrics/metrics.conf'),
    mode    => 0644,
    require => File["/usr/lib/sysctl.d"],
  }


  exec { "sysctl-system":
    path    => ["/sbin", "/bin", "/usr/bin"],
    command => "/sbin/sysctl --system",
    require => File["/usr/lib/sysctl.d/metrics.conf"],
  }


  #####################################################
  # install redis
  #####################################################

  package { "redis":
    ensure   => present,
    notify   => Exec['ldconfig'],
    require => Exec["no-thp"],
  }


  file { '/etc/redis.conf':
    ensure       => file,
    content      => template('metrics/redis.conf'),
    mode         => 0644,
    require      => Package['redis'],
  }


  file { ["/etc/systemd/system/redis.service.d",
         "/etc/systemd/system/redis-sentinel.service.d"]:
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/systemd/system/redis.service.d/limit.conf":
    ensure  => present,
    content => template('metrics/redis_service.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/redis.service.d"],
  }


  file { "/etc/systemd/system/redis-sentinel.service.d/limit.conf":
    ensure  => present,
    content => template('metrics/redis_service.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/redis-sentinel.service.d"],
  }


  service { 'redis':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/redis.conf'],
                   File['/etc/systemd/system/redis.service.d/limit.conf'],
                   File['/etc/systemd/system/redis-sentinel.service.d/limit.conf'],
                   Exec['daemon-reload'],
                  ],
  }


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


  cat_split_file { "logstash-oss-7.16.3.tar.gz":
    install_dir => "/etc/puppet/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "logstash-oss-7.16.3.tar.gz":
    install_dir => "/home/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Cat_split_file["logstash-oss-7.16.3.tar.gz"],
               ]
  }


  file { "/home/$user/logstash":
    ensure => 'link',
    target => "/home/$user/logstash-oss-7.16.3",
    owner => $user,
    group => $group,
    require => Tarball['logstash-oss-7.16.3.tar.gz'],
  }


  file { "$metrics_dir/etc/indexer.conf":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0644,
    content => template('metrics/indexer.conf'),
    require => File["/home/$user/logstash"],
  }


  cat_split_file { "kibana-7.9.3-linux-x86_64.tar.gz":
    install_dir => "/etc/puppet/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "kibana-7.9.3-linux-x86_64.tar.gz":
    install_dir => "/home/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Cat_split_file["kibana-7.9.3-linux-x86_64.tar.gz"],
               ],
  }


  file { "/home/$user/kibana":
    ensure => 'link',
    target => "/home/$user/kibana-7.9.3-linux-x86_64",
    owner => $user,
    group => $group,
    require => Tarball["kibana-7.9.3-linux-x86_64.tar.gz"],
  }


#  file { "/home/$user/kibana/config/kibana.yml":
#    ensure  => present,
#    owner   => $user,
#    group   => $group,
#    mode    => 0644,
#    content => template('metrics/kibana.yml'),
#    require => File["/home/$user/kibana"],
#  }


  file { "$metrics_dir/etc/supervisord.conf":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0644,
    content => template('metrics/supervisord.conf'),
    require => File["$metrics_dir/etc"],
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


  service { 'httpd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/httpd/conf.d/autoindex.conf'],
                   File['/etc/httpd/conf.d/welcome.conf'],
                   File['/etc/httpd/conf.d/ssl.conf'],
                   File['/var/www/html/index.html'],
                   Exec['daemon-reload'],
                  ],
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


  file { "/tmp/wait-for-it.sh":
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


#  exec { "import_dashboards":
#    path    => ["/sbin", "/bin", "/usr/bin"],
#    command => "/tmp/import_dashboards.sh",
#    require => [
#                File['/tmp/worker_metrics.json'],
#                File['/tmp/job_metrics.json'],
#                File['/tmp/wait-for-it.sh'],
#                File['/tmp/import_dashboards.sh'],
#                File["/home/$user/kibana/config/kibana.yml"],
#                File["$metrics_dir/run"],
#                Service['elasticsearch'],
#               ],
#  }


  #####################################################
  # firewalld config
  #####################################################

  firewalld::zone { 'public':
    services => [ "ssh", "dhcpv6-client", "http", "https" ],
    ports => [
      {
        # Kibana
        port     => "5601",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9200",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9300",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9300",
        protocol => "udp",
      },
      {
        # Redis
        port     => "6379",
        protocol => "tcp",
      },
    ]
  }


  #firewalld::service { 'dummy':
  #  description	=> 'My dummy service',
  #  ports       => [{port => '1234', protocol => 'tcp',},],
  #  modules     => ['some_module_to_load'],
  #  destination	=> {ipv4 => '224.0.0.251', ipv6 => 'ff02::fb'},
  #}


}
