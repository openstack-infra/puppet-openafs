# Class: openafs::client

class openafs::client (
  $realm,
  $cell,
  $kdcs = [$::fqdn],
  $admin_server = [$::fdqn],
  $cache_size = 500000,
) {

  include ::ntp
  class { '::kerberos::client':
    realm        => $realm,
    kdcs         => $kdcs,
    admin_server => $admin_server,
  }

  $packages = [
    'openafs-client',
    'openafs-krb5',
  ]
  package { $packages:
    ensure => present,
  }

  if ($::osfamily == 'RedHat') {
    $openafs_path = '/usr/vice/etc'

    $dkms_packages = [
      'kernel-devel',
      'dkms',
      'gcc'
    ]

    package { $dkms_packages:
      ensure => present,
      before => [
        Package['openafs-client'],
        Package['openafs-krb5'],
      ],
    }

    package { 'dkms-openafs':
      ensure  => present,
      require => [
        Package['kernel-devel'],
        Package['gcc'],
        Package['dkms'],
      ],
      before  => [
        Package['openafs-client'],
        Package['openafs-krb5'],
      ],
    }

    file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-OPENAFS':
      ensure  => present,
      replace => true,
      source  => 'puppet:///modules/openafs/RPM-GPG-KEY-OPENAFS',
      before  => [
        Package['openafs-client'],
        Package['openafs-krb5'],
      ],
    }

    file { '/etc/yum.repos.d/openafs-rhel.repo':
      ensure  => present,
      replace => true,
      source  => 'puppet:///modules/openafs/openafs-rhel.repo',
      before  => [
        Package['openafs-client'],
        Package['openafs-krb5'],
      ],
    }

    file { '/var/cache/openafs':
      ensure => directory,
    }

  } else {
    $openafs_path = '/etc/openafs'
  }

  file { "${openafs_path}/afs.conf.client":
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/openafs/afs.conf.client',
    require => Package['openafs-client'],
  }

  file { "${openafs_path}/CellServDB":
    ensure  => present,
    replace => true,
    source  => 'puppet:///modules/openafs/CellServDB',
    require => Package['openafs-client'],
  }

  file { "${openafs_path}/ThisCell":
    ensure  => present,
    replace => true,
    content => template('openafs/ThisCell.erb'),
    require => Package['openafs-client'],
  }

  file { "${openafs_path}/cacheinfo":
    ensure  => present,
    replace => true,
    content => template('openafs/cacheinfo.erb'),
    require => Package['openafs-client'],
  }

  service { 'openafs-client':
    ensure  => running,
    require => [
      File["${openafs_path}/CellServDB"],
    ],
  }
}
