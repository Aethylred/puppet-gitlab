class gitlab::params {
  $user               = 'git'
  $user_home          = '/home/git'
  $gitlab_shell_repo  = 'https://gitlab.com/gitlab-org/gitlab-shell.git'
  $gitlab_shell_rev   = 'v1.9.6'
  $gitlab_app_repo    = 'https://gitlab.com/gitlab-org/gitlab-ce.git'
  $gitlab_app_rev     = '7-1-stable'
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