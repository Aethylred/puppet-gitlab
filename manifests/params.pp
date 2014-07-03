class gitlab::params {
  $user = 'git'
  $user_home = '/home/git'

  case $::osfamily {
    Debian:{
      # Do nothing
    }
    default:{
      fail("The GitLab Puppet module does not support ${::osfamily} family of operating systems")
    }
  }
}