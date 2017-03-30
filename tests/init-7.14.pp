class{'git': }

# required to meet dependencies for bundling the gems
package{'libicu-dev':
  ensure => 'present',
}

package{'libkrb5-dev':
  ensure => 'present',
}

package{'cmake':
  ensure => 'present',
}

class{'apache':
  default_vhost => false,
  log_formats   => { common_forwarded => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b'},
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

# Setting the gitlab_url used by gitlab shell to use localhost
# because the FQDN of a test VM is unlikly to be real.
class{'gitlab':
  gitlab_url        => 'http://localhost/',
  gitlab_app_repo   => 'https://github.com/gitlabhq/gitlabhq.git',
  gitlab_app_rev    => '7-14-stable',
  gitlab_shell_repo => 'https://github.com/gitlabhq/gitlab-shell.git',
  gitlab_shell_rev  => 'v2.6.5',
  require           => [
    Class[
      'git',
      'postgresql::lib::devel'
    ],
    Package[
      'libicu-dev',
      'cmake',
      'libkrb5-dev'
    ]
  ]
}
