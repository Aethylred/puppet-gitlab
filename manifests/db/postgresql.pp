class gitlab::db::postgresql (
  $db_name              = $::gitlab::db_name,
  $db_user              = $::gitlab::db_user,
  $db_user_password     = $::gitlab::db_user_password,
  $db_user_passwd_hash  = undef,
  $gitlab_server        = $::gitlab::servername,
  $db_host              = $::fqdn
) inherits gitlab::params {

  if $db_user_passwd_hash {
    $_db_user_password = $db_user_passwd_hash
  } else {
    $_db_user_password = postgresql_password($db_user, $db_user_password)
  }

  postgresql::server::role{$db_user:
    password_hash => $_db_user_password,
  }

  postgresql::server::database{$db_name:
    owner     => $db_user,
  }

  postgresql::server::database_grant{'gitlab_db_grant':
    db        => $db_name,
    role      => $db_user,
    privilege => 'ALL',
  }

}