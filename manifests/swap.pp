define metrics::swap (
  $ensure   = 'present',
  $swapfile = $name,
  $swapsize = $::memorysize_mb
) {
  $swapsizes = split("${swapsize}", '[.]')
  $size = $swapsizes[0] + 0

  if $size > 65536 {
    $swapfilesize = 8096
  }
  else {
    $swapfilesize = $size
  }

  file_line { "swap_fstab_line_${swapfile}":
    ensure => $ensure,
    line   => "${swapfile} swap swap defaults 0 0",
    path   => "/etc/fstab",
    match  => "${swapfile}",
  }

  if $ensure == 'present' {
    exec { 'Create swap file':
      # fallocate fails on xfs filesystem, the default for centos:
      # https://bugzilla.redhat.com/show_bug.cgi?id=1129205
      #command => "/bin/fallocate -l ${swapfilesize}M ${swapfile}",
      command => "/bin/dd if=/dev/zero of=${swapfile} count=${swapfilesize} bs=1MiB",
      creates => $swapfile,
      timeout => 1800,
    }

    file { "${swapfile}":
      ensure  => file,
      mode    => 0600,
      require => Exec['Create swap file'],
    }

    exec { 'Attach swap file':
      command => "/sbin/mkswap ${swapfile} && /sbin/swapon ${swapfile}",
      require => File["${swapfile}"],
      unless  => "/sbin/swapon -s | grep ${swapfile}",
    }
  } elsif $ensure == 'absent' {
    exec { 'Detach swap file':
      command => "/sbin/swapoff ${swapfile}",
      onlyif  => "/sbin/swapon -s | grep ${swapfile}",
    }

    file { $swapfile:
      ensure => absent,
      require => Exec['Detach swap file'],
      backup => false,
    }
  }
}
