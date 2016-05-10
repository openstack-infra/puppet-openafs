# Class openafs::fileserver

class openafs::fileserver (
  $cell,
  $dbservers,
) {

  file { '/etc/openafs/server':
    ensure  => directory,
    require => Class['Openafs::Client'],
  }

  file { '/etc/openafs/server/CellServDB':
    ensure  => present,
    replace => true,
    content => template('openafs/server.CellServDB.erb'),
    require => File['/etc/openafs/server'],
  }

  file { '/etc/openafs/server/ThisCell':
    ensure  => present,
    replace => true,
    content => template('openafs/ThisCell.erb'),
    require => File['/etc/openafs/server'],
  }

  package { 'openafs-fileserver':
    ensure  => present,
    require => [
      File['/etc/openafs/server/CellServDB'],
    ],
  }

  # yes, this belongs here. the fileserver service runs bosserver
  service { 'openafs-fileserver':
    ensure  => running,
    require => [
      File['/etc/openafs/server/CellServDB'],
      Package['openafs-fileserver'],
    ],
  }

  sysctl::value { "net.core.rmem_max": value => "16777216"}
  sysctl::value { "net.core.wmem_max": value => "16777216"}
  sysctl::value { "net.core.rmem_default": value => "65536"}
  sysctl::value { "net.core.wmem_default": value => "65536"}
  sysctl::value { "net.ipv4.tcp_rmem": value => "'4096 87380 16777216'"}
  sysctl::value { "net.ipv4.tcp_wmem": value => "'4096 65536 16777216'"}
  sysctl::value { "net.ipv4.udp_rmem_min": value => "65536"}
  sysctl::value { "net.ipv4.udp_wmem_min": value => "65536"}
  sysctl::value { "net.ipv4.route.flush": value => "1"}
}
