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
  $gitlab_url             = 'http://localhost/',
  $relative_url_root      = '/gitlab',
  $port                   = '80',
  $enable_https           = false,
  $email_address          = undef,
  $user                   = $::gitlab::params::user,
  $user_home              = $::gitlab::params::user_home,
  $install_gl_shell       = true,
  $gitlab_shell_repo      = $::gitlab::params::gitlab_shell_repo,
  $gitlab_shell_rev       = $::gitlab::params::gitlab_shell_rev,
  $manage_db              = true,
  $db_user                = $::gitlab::params::user,
  $db_name                = $::gitlab::params::db_name,
  $db_host                = undef,
  $db_port                = undef,
  $db_user_password       = 'veryveryunsafe',
  $db_user_passwd_hash    = undef,
  $servername             = $::fqdn,
  $selfsigned_certs       = true,
  $audit_usernames        = false,
  $log_level              = 'INFO',
  $gl_shell_logfile       = undef,
  $gitlab_app_dir         = undef,
  $gitlab_app_repo        = $::gitlab::params::gitlab_app_repo,
  $gitlab_app_rev         = $::gitlab::params::gitlab_app_rev,
  $default_project_limit  = 10,
  $allow_group_creation   = true,
  $allow_name_change      = true,
  $default_theme_id       = 2,
  $project_issues         = true,
  $project_merge_requests = true,
  $project_wiki           = true,
  $project_snippets       = false,
  $project_visibility     = 'private',
  $enable_gravatar        = true,
  $ssh_port               = undef
) inherits gitlab::params {

  validate_bool($install_gl_shell, $manage_db, $enable_https, $selfsigned_certs, $audit_usernames)
  validate_bool($allow_name_change, $allow_group_creation, $enable_gravatar)
  validate_bool($project_snippets, $project_wiki, $project_issues)
  validate_re($project_visibility, ['^private$', '^public$', '^internal$'])

  $repository_dir = "${user_home}/repositories"
  $auth_file      = "${user_home}/.ssh/authorized_keys"
  if $gitlab_app_dir {
    $app_dir = $gitlab_app_dir
  } else {
    $app_dir = "${user_home}/gitlab"
  }
  if $email_address {
    $real_email = $email_address
  } else {
    $real_email = "${user}@${servername}"
  }

  user{'gitlab':
    ensure        => present,
    name          => $user,
    home          => $user_home,
    password      => '!',
    comment       => 'GitLab services and application user',
    managehome    => true,
    shell         => '/bin/bash',
  }

  git::user{$user:
    user_name   => 'GitLab',
    user_email  => $real_email,
    require     => User['gitlab'],
  }

  file{'gitlab_home':
    ensure  => 'directory',
    path    => $user_home,
    owner   => $user,
    recurse => true,
  }

  file{'gitlab_repostiories_dir':
    ensure  => 'directory',
    path    => $repository_dir,
    owner   => $user,
    recurse => true,
  }

  file{'gitlab_auth_file':
    ensure  => 'file',
    path    => $auth_file,
    owner   => $user,
    mode    => '0600',
  }

  if $install_gl_shell {
    class{'gitlab::shell::install':
      gitlab_url        => $gitlab_url,
      user              => $user,
      user_home         => $user_home,
      repository        => $gitlab_shell_repo,
      revision          => $gitlab_shell_rev,
      repository_dir    => $repository_dir,
      auth_file         => $auth_file,
      selfsigned_certs  => $selfsigned_certs,
      audit_usernames   => $audit_usernames,
      log_level         => $log_level,
      gl_shell_logfile  => $gl_shell_logfile,
      before            => Ruby::Bundle['gitlab_install'],
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

  class{'gitlab::install':
    app_dir     => $app_dir,
    repository  => $gitlab_app_repo,
    revision    => $gitlab_app_rev,
    user        => $user,
  }

  file{'gitlab_app_config':
    ensure  => 'file',
    path    => "${app_dir}/config/gitlab.yml",
    owner   => $user,
    group   => $user,
    content => template('gitlab/app/gitlab.yml.erb'),
    require => Class['gitlab::install'],
  }

  file{'gitlab_db_config':
    ensure  => 'file',
    path    => "${app_dir}/config/database.yml",
    owner   => $user,
    group   => $user,
    content => template('gitlab/app/database.yml.erb'),
    require => Class['gitlab::install'],
  }

  ruby::bundle{'gitlab_install':
    command     => 'install',
    option      => '--deployment --path=vendor/bundle --without test development mysql aws',
    environment => ["HOME=${user_home}"],
    cwd         => $app_dir,
    user        => $user,
    # multicore   => '0',
    timeout     => '600',
    require     => [
      File['gitlab_db_config','gitlab_app_config']
    ],
  }

  ruby::rake{'gitlab_setup':
    task        => 'gitlab:setup',
    environment => ['force=yes',"HOME=${user_home}"],
    bundle      => true,
    refreshonly => true,
    cwd         => $app_dir,
    user        => $user,
    subscribe   => Ruby::Bundle['gitlab_install'],
  }
}
