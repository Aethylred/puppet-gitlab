# This test should install gitlab on Ubuntu 12.04LTS
include apt
apt::ppa{'ppa:git-core/ppa':}
apt::ppa{'ppa:brightbox/ruby-ng-experimental':}
class{'git':
  require => Apt::Ppa['ppa:git-core/ppa'],
}
include apache
include apache::mod::passenger

class{'ruby':
  version => '2.0',
  switch  => true,
  require => Apt::Ppa['ppa:brightbox/ruby-ng-experimental']
}

include postgresql::server

class{'gitlab':
  require  => [Class['ruby','git']]
}
