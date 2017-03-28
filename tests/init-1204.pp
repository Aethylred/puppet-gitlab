# This test should install gitlab on Ubuntu 12.04LTS
include apt
apt::ppa{'ppa:git-core/ppa':}
apt::ppa{'ppa:brightbox/ruby-ng-experimental':}
class{'git':
  require => Apt::Ppa['ppa:git-core/ppa'],
}
# package{'rubygems-integration':
#   ensure  => 'present',
#   require => Apt::Ppa['ppa:brightbox/ruby-ng-experimental'],
# }
package{'libicu-dev':
  ensure => 'present',
}

include apache
include apache::mod::passenger
include redis

class{'ruby':
  version        => '2.0.0',
  latest_release => true,
  switch         => true,
  require        => Apt::Ppa['ppa:brightbox/ruby-ng-experimental']
}
class{'ruby::dev':
  bundler_package  => 'bundler',
  bundler_provider => 'gem',
}

include postgresql::server
class {'postgresql::lib::devel':
  link_pg_config => false,
}

class{'gitlab':
  require  => [
    Class[
      'ruby',
      'git',
      'postgresql::lib::devel',
      'redis'
    ],
    Package[
#      'rubygems-integration',
      'libicu-dev'
    ]
  ]
}
