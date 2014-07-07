class gitlab::shell::install (
  $user       = $::gitlab::user,
  $user_home  = $::gitlab::user_home,
  $repository = $::gitlab::params::gitlab_shell_repo,
  $revision   = $::gitlab::params::gitlab_shell_rev
) inherits gitlab::params {

  vcsrepo{'gitlab-shell':
    ensure    => 'present',
    path      => "${user_home}/gitlab-shell",
    provider  => git,
    user      => $user,
    source    => $repository,
    revision  => $revision,
    require   => User['gitlab'],
  }

  file{'gitlab-shell-config':
    ensure  => 'file',
    path    => "${user_home}/gitlab-shell/config.yml",
    owner   => $user,
    group   => $user,
    content => template('gitlab/gitlab-shell-config.yml.erb'),
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