# Contains global variables and parameters
class gitlab::params {
  $user               = 'git'
  $user_home          = '/home/git'
  $gitlab_shell_repo  = 'https://github.com/gitlabhq/gitlab-shell.git'
  $gitlab_shell_rev   = 'v2.0.1'
  $gitlab_app_repo    = 'https://github.com/gitlabhq/gitlabhq.git'
  $gitlab_app_rev     = '7-4-stable'
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
