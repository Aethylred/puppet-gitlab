class{'git': }

# required to meet dependencies for bundling the gems

case $::osfamily{
  'Debian':{
    $dep_packages = [
      'build-essential',
      'zlib1g-dev',
      'libyaml-dev',
      'libssl-dev',
      'libgdbm-dev',
      'libreadline-dev',
      'libncurses5-dev',
      'libffi-dev',
      'curl',
      'openssh-server',
      'checkinstall',
      'libxml2-dev',
      'libxslt-dev',
      'libcurl4-openssl-dev',
      'libicu-dev',
      'logrotate',
      'python-docutils',
      'cmake',
      'libkrb5-dev'
    ]
  }
  'RedHat':{
    class{'epel':
      before => Class['redis','nodejs','apache','ruby'],
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

class{'apache':
  default_vhost => false,
  log_formats   => { common_forwarded => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b'},
}
include apache::mod::passenger
include redis
class{'nodejs':
  #npm_package_ensure => 'present',
  before             => Class['gitlab'],
}

class{'ruby':
  version            => '2.1.0',
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
  ]
}
