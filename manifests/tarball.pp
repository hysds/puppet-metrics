define metrics::tarball($pkg_tar=$title, $install_dir, $owner, $group) {

  # create the install directory
  unless defined(File["$install_dir"]) {
    file { "$install_dir":
      ensure  => directory,
      owner   => $owner,
      group   => $group,
      mode    => 0755,
    }
  }

  # download the tar file
  file { "$pkg_tar":
    path    => "/tmp/$pkg_tar",
    source  => "puppet:///modules/metrics/$pkg_tar",
    notify  => Exec["untar $pkg_tar"],
  }

  # untar the tarball at the desired location
  exec { "untar $pkg_tar":
    path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command => "/bin/tar xvf /tmp/$pkg_tar --owner $owner --group $group -C $install_dir/",
    refreshonly => true,
    require => File["/tmp/$pkg_tar", "$install_dir"],
    notify  => Exec["chown $pkg_tar"],
  }

  # ensure ownership
  exec { "chown $pkg_tar":
    path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command => "chown -R $owner:$group $install_dir",
    refreshonly => true,
    require => Exec["untar $pkg_tar"],
  }
}
