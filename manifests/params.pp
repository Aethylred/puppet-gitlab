class gitlab::params {
  $user               = 'git'
  $user_home          = '/home/git'
  $gitlab_shell_repo  = 'https://gitlab.com/gitlab-org/gitlab-shell.git'
  $gitlab_shell_rev   = 'v1.8.0'
  $db_name            = 'gitlab'

  case $::osfamily {
    Debian:{
      # Do nothing
    }
    default:{
      fail("The GitLab Puppet module does not support ${::osfamily} family of operating systems")
    }
  }
}