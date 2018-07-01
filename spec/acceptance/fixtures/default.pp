class { 'openafs::client':
  cell         => 'openstack.org',
  realm        => 'OPENSTACK.ORG',
}

class { '::openafs::fileserver':
  cell         => 'openstack.org',
  dbservers    => [
    {
      name     => 'localhost',
      ip       => '127.0.0.1',
    }
  ],
}

class { '::openafs::dbserver': }
