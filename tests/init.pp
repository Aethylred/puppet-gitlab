class{'git': }
 
package{'libicu-dev':
  ensure => 'present',
}

include apache
include apache::mod::passenger
include redis

class{'ruby':
  version         => '2.0.0',
}
class{'ruby::dev':
  bundler_package   => 'bundler',
  bundler_provider  => 'gem',
}

include postgresql::server
include postgresql::lib::devel

class{'gitlab':
  require  => [
    Class[
      'ruby',
      'git',
      'postgresql::lib::devel',
      'redis'
    ],
    Package[
      'libicu-dev'
    ]
  ]
}
