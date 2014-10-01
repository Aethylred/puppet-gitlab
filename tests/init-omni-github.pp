class{'git': }

# required to meet dependencies for bundling the gems
package{'libicu-dev':
  ensure => 'present',
}

class{'apache':
  default_vhost     => false,
  server_signature  => 'off',
  log_formats       => { common_forwarded => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b'},
}
include apache::mod::passenger
include redis

class{'ruby':
  version             => '2.0.0',
  set_system_default  => true,
}
class{'ruby::dev':
  bundler_package   => 'bundler',
  bundler_provider  => 'gem',
}

include postgresql::server
include postgresql::lib::devel

# Upload some SSL certificates and keys here.

# Setting the gitlab_url used by gitlab shell to use localhost
# because the FQDN of a test VM is unlikly to be real.
class{'gitlab':
  gitlab_url    => 'http://localhost/',
  enable_https  => true,
  redirect_http => true,
  omniauth      => [
    {
      'provider'    => 'github',
      'app_id'      => 'YOURIDHERE',
      'app_secret'  => 'YOURHASHHERE'
    }
  ],
  require       => [
    Class[
      'git',
      'postgresql::lib::devel'
    ],
    Package[
      'libicu-dev'
    ]
  ]
}
