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
  version            => '2.1.0',
  set_system_default => true,
}

include ruby::dev


include postgresql::server
class {'postgresql::lib::devel':
  link_pg_config => false,
}

# Upload some SSL certificates and keys here.

# Setting the gitlab_url used by gitlab shell to use localhost
# because the FQDN of a test VM is unlikly to be real.
class{'gitlab':
  gitlab_url        => 'https://localhost/',
  enable_https      => true,
  redirect_http     => true,
  gitlab_app_repo   => 'https://github.com/gitlabhq/gitlabhq.git',
  gitlab_app_rev    => '7-5-stable',
  gitlab_shell_repo => 'https://github.com/gitlabhq/gitlab-shell.git',
  gitlab_shell_rev  => 'v2.2.0',
  time_zone         => 'Pacific/Auckland',
  require           => [
    Class[
      'git',
      'postgresql::lib::devel'
    ],
  ]
}

# ssh_authorized_key{'git@git.local':
#   user    => 'git',
#   type    => 'ssh-rsa',
#   options => [
#     'command="/home/git/gitlab-shell/bin/gitlab-shell key-1"',
#     'no-port-forwarding',
#     'no-X11-forwarding',
#     'no-agent-forwarding',
#     'no-pty'
#   ],
#   key     => 'arillylonghash'
# }

gitlab::shell::repo{'a test':
  group   => 'test',
  project => 'testing'
}

# you need to login as an admin and add a user to this project to test these
# scripts work when you push to the repository.

gitlab::shell::repo::hook{'update':
  target  => 'a test',
  content => "#!/bin/bash\necho 'this is a test of the update hook'\npwd\nsource ./custom_hooks/update-part2",
}

gitlab::shell::repo::hook{'update-part2':
  target  => 'a test',
  content => "#!/bin/bash\necho 'this is a test of a chained update hook'",
}

gitlab::shell::repo::hook{'pre-receive':
  target  => 'a test',
  content => "#!/bin/bash\necho 'this is a test of the pre-receive hook'",
}

gitlab::shell::repo::hook{'post-receive':
  target  => 'a test',
  content => "#!/bin/bash\necho 'this is a test of the post-receive hook'",
}