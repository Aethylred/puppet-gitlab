# This defines a git repository created via the Gitlab shell
define gitlab::shell::repo (
  $group,
  $project
) {

  validate_string($group,$project)
  validate_re($group,'^[a-zA-Z0-9]*$')
  validate_re($project,'^[a-zA-Z0-9]*$')
  $repo_name = "${group}/${project}.git"
  $repo_path = "${gitlab::repository_dir}/${repo_name}"

  exec{"create_gitlab_shell_repo_${name}":
    command     => "${gitlab::user_home}/gitlab-shell/bin/gitlab-projects add-project ${repo_name}",
    user        => $gitlab::user,
    creates     => $repo_path,
    environment => ['RAILS_ENV=production'],
    notify      => Ruby::Rake['gitlab_import_repos'],
    path        => ['/bin','/usr/bin'],
  }

  file {"${repo_name}_dir":
    ensure  => 'directory',
    path    => $repo_path,
    owner   => $gitlab::user,
    group   => $gitlab::user,
    recurse => true,
    require => Exec["create_gitlab_shell_repo_${name}"],
  }

  file {"${repo_name}_custom_hooks_dir":
    ensure  => 'directory',
    path    => "${gitlab::repository_dir}/${repo_name}/custom_hooks",
    owner   => $gitlab::user,
    group   => $gitlab::user,
    recurse => true,
    require => Exec["create_gitlab_shell_repo_${name}"],
  }

}