define gitlab::shell::repo (
  $group,
  $project
) {

  validate_string($group,$project)
  validate_re($group,'^[a-zA-Z0-9]*$')
  validate_re($project,'^[a-zA-Z0-9]*$')
  $repo_name = "${group}/${project}.git"

  exec{"create_gitlab_shell_repo_${name}":
    command     => "${gitlab::user_home}/gitlab-shell/bin/gitlab-projects add-project ${repo_name}",
    user        => $gitlab::user,
    creates     => "${gitlab::repository_dir}/${repo_name}",
    environment => ['RAILS_ENV=production'],
    notify      => Ruby::Rake['gitlab_import_repos'],
    path        => ['/bin','/usr/bin'],
  }

  file {"${gitlab::repository_dir}/${repo_name}":
    ensure  => 'directory',
    owner   => $gitlab::user,
    group   => $gitlab::user,
    recurse => true,
    require => Exec["create_gitlab_shell_repo_${name}"],
  }

}