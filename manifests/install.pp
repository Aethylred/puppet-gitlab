# This class installs the gitlab app from it's repository
class gitlab::install (
  $app_dir     = $::gitlab::app_dir,
  $repository  = $::gitlab::gitlab_app_repo,
  $revision    = $::gitlab::gitlab_app_rev,
  $user        = $::gitlab::user
) inherits gitlab::params {

  vcsrepo{'gitlab_app':
    ensure    => 'present',
    path      => $app_dir,
    provider  => 'git',
    user      => $user,
    source    => $repository,
    revision  => $revision,
    require   => User['gitlab'],
    notify    => Ruby::Bundle['gitlab_install'],
  }

  file{'gitlab_app_dir':
    ensure  => 'directory',
    path    => $app_dir,
    owner   => $user,
    recurse => true,
    require => Vcsrepo['gitlab_app']
  }

}
