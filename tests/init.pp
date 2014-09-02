class{'git': }
 
package{'libicu-dev':
  ensure => 'present',
}

class{'apache':
  default_vhost => false,
  log_formats     => { common_forwarded => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b'},
}
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
  relative_url_root => '/',
  require           => [
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
