define metrics::update_alternatives ($path) {
  exec { "set-${name}":
    path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command => "update-alternatives --set ${name} ${path}",
    unless => "update-alternatives --display ${name} | grep 'points to' | grep -q '${path}'",
  }
}
