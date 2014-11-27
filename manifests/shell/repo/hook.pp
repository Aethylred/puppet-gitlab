# This defines a git hook script as implemented in Gitlab shell
# This requires Gitlab shell v2.2.0 or later
define gitlab::shell::repo::hook (
  $target,
  $path    = $name,
  $content = undef,
  $source  = undef
) {

  # To Do: A version check may be required,
  # that will involve exposing the Gitlab & Gitlab shell version
  # as a fact

  validate_re($path, '^[a-z]([a-zA-Z0-9_\-\.\/]*)$')

  $repo_group   = getparam(Gitlab::Shell::Repo[$target], 'group')
  $repo_project = getparam(Gitlab::Shell::Repo[$target], 'project')
  $repo_name    = "${repo_group}/${repo_project}.git"
  $hook_dir     = "${gitlab::repository_dir}/${repo_name}/custom_hooks"
  $hook_path    = "${hook_dir}/${path}"

  if $content and $source {
    fail('gitlab::shell::repo::hook requires only one of content or source parameter, but not both')
  } elsif $content {
    file{"${target}_hook_${name}":
      ensure  => 'file',
      path    => $hook_path,
      owner   => $gitlab::user,
      group   => $gitlab::user,
      mode    => '0750',
      content => $content,
      require => [File[$hook_dir],Gitlab::Shell::Repo[$target]]
    }
  } elsif $source {
    file{"${target}_hook_${name}":
      ensure  => 'file',
      path    => $hook_path,
      owner   => $gitlab::user,
      group   => $gitlab::user,
      mode    => '0750',
      source  => $source,
      require => [File[$hook_dir],Gitlab::Shell::Repo[$target]]
    }
  } else {
    fail('gitlab::shell::repo::hook requires a content or source parameter, but niether have been provided')
  }

}