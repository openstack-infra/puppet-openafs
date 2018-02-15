# Class: openafs::client

class openafs::client (
  $cell,
  $realm,
  $admin_server = [$::fdqn],
  $cache_size   = 500000,
  $kdcs         = [$::fqdn],
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
    'kstart',
  ]
  package { $packages:
    ensure => present,
  }

  if ($::osfamily == 'RedHat') {

    # There is no official release of AFS for RHEL/CentOS7 at this
    # stage.  We are pointing this to RPMs we have build in a job at
    # tarballs.openstack.org, and we only build for 7 ATM
    #  TODO: fedora
    if versioncmp($::operatingsystemmajrelease, '7') != 0 {
      fail('We only support Centos7 builds at this time')
    }

    $openafs_path = '/usr/vice/etc'

    if ! defined(Package['kernel-devel']) {
      package { 'kernel-devel':
        ensure => present,
        before => [
          Package['openafs-client'],
          Package['openafs-krb5'],
        ],
      }
    }

    if ! defined(Package['dkms']) {
      package { 'dkms':
        ensure => present,
        before => [
          Package['openafs-client'],
          Package['openafs-krb5'],
        ],
      }
    }

    if ! defined(Package['gcc']) {
      package { 'gcc':
        ensure => present,
        before => [
          Package['openafs-client'],
          Package['openafs-krb5'],
        ],
      }
    }

    $openafs_dkms = 'dkms-openafs'
    package { $openafs_dkms:
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

    file { '/etc/yum.repos.d/openafs.repo':
      ensure  => present,
      replace => true,
      source  => 'puppet:///modules/openafs/openafs.repo',
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

    if ($::architecture == 'aarch64') {
      if ($::libdistcodename != 'xenial') {
        fail('arm64 only supported on Xenial at this time')
      }
      # Note arm64 == aarch64 ...

      # ARM64 wasn't supported in openafs until
      #  https://gerrit.openafs.org/11940
      # This custom PPA has 1.8.x packages with these patches
      include ::apt
      apt::ppa { 'ppa:openstack-ci-core/openafs-arm64': }

      # We use the HWE kernel for aarch
      $dkms_packages = ['linux-generic-hwe-16.04',
                        'linux-headers-generic-hwe-16.04',]
      $dkms_requires = [Apt::Ppa['ppa:openstack-ci-core/openafs-arm64'],
                        Class['apt::update'],]
    } else {
      $dkms_packages = ['linux-headers-generic',]
      $dkms_requires = []
    }

    $openafs_dkms = 'openafs-modules-dkms'
    package { $dkms_packages:
      ensure  => present,
      before  => [
        Package['openafs-client'],
        Package['openafs-krb5'],
        Package[$openafs_dkms],
      ],
      require => $dkms_requires,
    }
    package { $openafs_dkms:
      ensure => present,
      notify => Service['openafs-client'],
    }
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
    ensure    => running,
    enable    => true,
    hasstatus => false,
    pattern   => '/sbin/afsd',
    require   => [
      File["${openafs_path}/CellServDB"],
      Package[$openafs_dkms],
    ],
  }
}
