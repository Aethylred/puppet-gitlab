# Class: gitlab
#
# This module manages gitlab
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

# This file is part of the gitlab Puppet module.
#
#     The gitlab Puppet module is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     The gitlab Puppet module is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with the gitlab Puppet module.  If not, see <http://www.gnu.org/licenses/>.

# [Remember: No empty lines between comments and class definition]
class gitlab (
  $gitlab_url           = 'http://localhost',
  $user                 = $::gitlab::params::user,
  $user_home            = $::gitlab::params::user_home,
  $install_gl_shell     = true,
  $gitlab_shell_repo    = $::gitlab::params::gitlab_shell_repo,
  $gitlab_shell_rev     = $::gitlab::params::gitlab_shell_rev,
  $manage_db            = true,
  $db_user              = $::gitlab::params::user,
  $db_name              = $::gitlab::params::db_name,
  $db_user_password     = 'veryveryunsafe',
  $db_user_passwd_hash  = undef,
  $servername           = $::fqdn,
  $selfsigned_certs     = undef,
  $audit_usernames      = undef,
  $log_level            = 'INFO',
  $gl_shell_logfile     = undef
) inherits gitlab::params {

  user{'gitlab':
    ensure        => present,
    name          => $user,
    home          => $user_home,
    password      => '!',
    comment       => 'GitLab services and application user',
    managehome    => true,
    shell         => '/bin/bash',
  }

  file{'gitlab_home':
    ensure  => 'directory',
    path    => $user_home,
    owner   => $user,
    recurse => true,
  }

  if $install_gl_shell {
    class{'gitlab::shell::install':
      user        => $user,
      user_home   => $user_home,
      repository  => $gitlab_shell_repo,
      revision    => $gitlab_shell_rev,
    }
  }

  if $manage_db {
    # use a case here if other database providers are ever implemented
    class{'gitlab::db::postgresql':
      db_user             => $db_user,
      db_name             => $db_name,
      db_user_password    => $db_user_password,
      db_user_passwd_hash => $db_user_passwd_hash,
      gitlab_server       => $servername,
      db_host             => $servername,
    }
  }


}
