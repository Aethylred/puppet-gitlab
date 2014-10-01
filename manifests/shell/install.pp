# installs and configures the GitLab shell
class gitlab::shell::install (
  $gitlab_url       = $::gitlab::real_gitlab_url,
  $user             = $::gitlab::user,
  $user_home        = $::gitlab::user_home,
  $repository       = $::gitlab::params::gitlab_shell_repo,
  $revision         = $::gitlab::params::gitlab_shell_rev,
  $repository_dir   = $::gitlab::repository_dir,
  $auth_file        = $::gitlab::auth_file,
  $selfsigned_certs = $::gitlab::selfsigned_certs,
  $audit_usernames  = $::gitlab::audit_usernames,
  $log_level        = $::gitlab::log_level,
  $gl_shell_logfile = $::gitlab::gl_shell_logfile
) inherits gitlab::params {

  require redis

  vcsrepo{'gitlab-shell':
    ensure   => 'present',
    path     => "${user_home}/gitlab-shell",
    provider => git,
    user     => $user,
    source   => $repository,
    revision => $revision,
    require  => User['gitlab'],
  }

  file{'gitlab-shell-config':
    ensure  => 'file',
    path    => "${user_home}/gitlab-shell/config.yml",
    owner   => $user,
    group   => $user,
    content => template('gitlab/shell/config.yml.erb'),
    require => Vcsrepo['gitlab-shell'],
  }

  exec{'gitlab_shell_install':
    cwd         => $user_home,
    user        => $user,
    command     => "${user_home}/gitlab-shell/bin/install",
    subscribe   => File['gitlab-shell-config'],
    refreshonly => true,
  }

}