#####################################################
# metrics class
#####################################################

class metrics inherits hysds_base {

  #####################################################
  # copy user files
  #####################################################
  
  file { "/$user/.bash_profile":
    ensure  => present,
    content => template('metrics/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => "0644",
    require => User[$user],
  }


  #####################################################
  # metrics directory
  #####################################################

  $metrics_dir = "/$user/metrics"


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
  # Architecture-specific JDK installation
  #####################################################

  # Determine architecture for multi-arch support
  $arch = $::architecture
  
  #####################################################
  # install OpenJDK 8 (multi-architecture compatible)
  # Uses system repositories instead of Oracle JDK RPMs
  #####################################################

  # Install OpenJDK 8 from system repositories
  # This works on both x86_64 and aarch64 without separate RPM files
  package { 'java-1.8.0-openjdk-devel':
    ensure => present,
    notify => Exec['ldconfig'],
  }

  # Set java alternatives to use OpenJDK 8
  # The path is architecture-independent for OpenJDK
  exec { 'set-java-alternatives':
    command => '/usr/sbin/alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk/bin/java',
    unless  => '/usr/sbin/alternatives --display java | grep "link currently points to /usr/lib/jvm/jre-1.8.0-openjdk/bin/java"',
    require => Package['java-1.8.0-openjdk-devel'],
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
  # install install_hysds.sh script and other config
  # files in root home
  #####################################################

  file { "/$user/install_hysds.sh":
    ensure  => present,
    content => template('metrics/install_hysds.sh'),
    owner   => $user,
    group   => $group,
    mode    => "0755",
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
    mode    => "0755",
    require => User[$user],
  }


  file { "$metrics_dir/bin/metricsd":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('metrics/metricsd'),
    require => File["$metrics_dir/bin"],
  }


  file { "$metrics_dir/bin/start_metrics":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('metrics/start_metrics'),
    require => File["$metrics_dir/bin"],
  }
 

  file { "$metrics_dir/bin/stop_metrics":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('metrics/stop_metrics'),
    require => File["$metrics_dir/bin"],
  }


  metrics::cat_split_file { "logstash-7.9.3.tar.gz":
    install_dir => "/etc/puppetlabs/code/modules/metrics/files",
    owner       =>  $user,
    group       =>  $group,
  }


  metrics::tarball { "logstash-7.9.3.tar.gz":
    install_dir => "/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Metrics::Cat_split_file["logstash-7.9.3.tar.gz"],
               ]
  }


  file { "/$user/logstash":
    ensure => 'link',
    target => "/$user/logstash-7.9.3",
    owner => $user,
    group => $group,
    require => Metrics::Tarball['logstash-7.9.3.tar.gz'],
  }


  file { "$metrics_dir/etc/indexer.conf":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0644",
    content => template('metrics/indexer.conf'),
    require => File["/$user/logstash"],
  }


  #####################################################
  # Install Kibana using tarball (architecture-specific)
  # Note: For ARM64, Kibana 7.9.3 tarball must be downloaded separately
  # and split into files. Alternatively, use a newer version from Elastic repos.
  #####################################################
  
  # Determine architecture-specific Kibana tarball
  # x86_64 uses x86_64, aarch64 uses aarch64
  if $arch == 'x86_64' {
    $kibana_tarball = "kibana-7.9.3-linux-x86_64.tar.gz"
    $kibana_dir = "kibana-7.9.3-linux-x86_64"
    
    metrics::cat_split_file { "$kibana_tarball":
      install_dir => "/etc/puppetlabs/code/modules/metrics/files",
      owner       =>  $user,
      group       =>  $group,
    }

    metrics::tarball { "$kibana_tarball":
      install_dir => "/$user",
      owner => $user,
      group => $group,
      require => [
                  User[$user],
                  Metrics::Cat_split_file["$kibana_tarball"],
                 ],
    }

    file { "/$user/kibana":
      ensure => 'link',
      target => "/$user/$kibana_dir",
      owner => $user,
      group => $group,
      require => Metrics::Tarball["$kibana_tarball"],
    }
  } elsif $arch == 'aarch64' {
    # For ARM64, download Kibana directly from Elastic
    # Kibana 7.9.3 ARM64 tarball is not included in the repo
    exec { 'download-kibana-arm64':
      command => "/usr/bin/curl -L -o /$user/kibana-7.9.3-linux-aarch64.tar.gz https://artifacts.elastic.co/downloads/kibana/kibana-7.9.3-linux-aarch64.tar.gz",
      creates => "/$user/kibana-7.9.3-linux-aarch64.tar.gz",
      require => User[$user],
    }

    exec { 'extract-kibana-arm64':
      command => "/usr/bin/tar -xzf /$user/kibana-7.9.3-linux-aarch64.tar.gz -C /$user",
      creates => "/$user/kibana-7.9.3-linux-aarch64",
      require => Exec['download-kibana-arm64'],
    }

    exec { 'chown-kibana-arm64':
      command => "/usr/bin/chown -R ${user}:${group} /$user/kibana-7.9.3-linux-aarch64",
      require => Exec['extract-kibana-arm64'],
      refreshonly => true,
      subscribe => Exec['extract-kibana-arm64'],
    }

    file { "/$user/kibana":
      ensure => 'link',
      target => "/$user/kibana-7.9.3-linux-aarch64",
      owner => $user,
      group => $group,
      require => Exec['extract-kibana-arm64'],
    }
  } else {
    fail("Unsupported architecture: ${arch}")
  }


#  file { "/$user/kibana/config/kibana.yml":
#    ensure  => present,
#    owner   => $user,
#    group   => $group,
#    mode    => "0644",
#    content => template('metrics/kibana.yml'),
#    require => File["/$user/kibana"],
#  }


  #####################################################
  # write rc.local to startup & shutdown metrics
  #####################################################

  file { '/etc/rc.d/rc.local':
    ensure  => file,
    content  => template('metrics/rc.local'),
    mode    => "0755",
  }


  #####################################################
  # secure and start httpd
  #####################################################

  file { "/etc/httpd/conf.d/autoindex.conf":
    ensure  => present,
    content => template('metrics/autoindex.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => present,
    content => template('metrics/welcome.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }

 
  file { "/etc/httpd/conf.d/ssl.conf":
    ensure  => present,
    content => template('metrics/ssl.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }

 
  file { '/var/www/html/index.html':
    ensure  => file,
    content => template('metrics/index.html'),
    mode    => "0644",
    require => Package['httpd'],
  }


  #####################################################
  # install job and worker kibana configs
  #####################################################

  file { "/tmp/worker_metrics.json":
    ensure  => present,
    content => template('metrics/worker_metrics.json'),
    mode    => "0644",
  }


  file { "/tmp/job_metrics.json":
    ensure  => present,
    content => template('metrics/job_metrics.json'),
    mode    => "0644",
  }


  file { "/wait-for-it.sh":
    ensure  => present,
    content => template('metrics/wait-for-it.sh'),
    owner   => $user,
    group   => $group,
    mode    => "0755",
  }


  file { "/tmp/import_dashboards.sh":
    ensure  => present,
    content => template('metrics/import_dashboards.sh'),
    owner   => $user,
    group   => $group,
    mode    => "0755",
  }

  #####################################################
  # generate ssl certs: problem with mod_ssl per
  # https://community.letsencrypt.org/t/localhost-crt-does-not-exist-or-is-empty/103979/4
  #####################################################

  exec { "httpd-ssl-gencerts":
    command => "/usr/libexec/httpd-ssl-gencerts",
    require => Package["mod_ssl"],
  }


}
