# Contains global variables and parameters
class gitlab::params {
  $user               = 'git'
  $user_home          = '/home/git'
  $gitlab_shell_repo  = 'https://gitlab.com/gitlab-org/gitlab-shell.git'
  $gitlab_shell_rev   = 'v2.6.5'
  $gitlab_app_repo    = 'https://gitlab.com/gitlab-org/gitlab-ce.git'
  $gitlab_app_rev     = '7-14-stable'
  $db_name            = 'gitlab'

  case $::osfamily {
    'Debian':{
      # Do nothing
    }
    'RedHat':{
      case $::operatingsystem {
        'RedHat', 'CentOS':  {
          # Do nothing
        }
        default:{
          fail("The GitLab Puppet module only supports RedHat or CentOS from the ${::osfamily} family of operating systems")
        }
      }
    }
    default:{
      fail("The GitLab Puppet module does not support ${::osfamily} family of operating systems")
    }
  }
}
