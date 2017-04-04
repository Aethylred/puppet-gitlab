class{'git': }

# required to meet dependencies for bundling the gems

case $::osfamily{
  'Debian':{
    $dep_packages = ['libicu-dev', 'libkrb5-dev']
  }
  'RedHat':{
    class{'epel':
      before => Class['redis','nodejs','apache','ruby']
    }
    $dep_packages = ['libicu-devel', 'krb5-devel', 'gcc-c++', 'zlib-devel', 'libxml2-devel']
  }
  default:{
    fail("The GitLab Puppet module does not support ${::osfamily} family of operating systems")
  }
}

package{$dep_packages:
  ensure => 'present',
  before => Class['gitlab','redis','nodejs'],
}

package{'cmake':
  ensure => 'present',
  before => Class['gitlab'],
}

class{'apache':
  default_vhost    => false,
  server_signature => 'off',
  log_formats      => { common_forwarded => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b'},
}
include apache::mod::passenger
include redis
include nodejs

class{'ruby':
  version            => '2.0.0',
  set_system_default => true,
}
class{'ruby::dev':
  bundler_package  => 'bundler',
  bundler_provider => 'gem',
}

include postgresql::server
class {'postgresql::lib::devel':
  link_pg_config => false,
}

# Upload some SSL certificates and keys here.

# Setting the gitlab_url used by gitlab shell to use localhost
# because the FQDN of a test VM is unlikly to be real.
class{'gitlab':
  gitlab_url    => 'http://localhost/',
  enable_https  => true,
  redirect_http => true,
  omniauth      => [
    {
      'provider'   => 'google',
      'app_id'     => 'YOURIDHERE',
      'app_secret' => 'YOURHASHHERE'
    }
  ],
  require       => [
    Class[
      'git',
      'postgresql::lib::devel'
    ],
  ]
}
