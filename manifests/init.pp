# Class: gitlab
#
# This module manages gitlab
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

# This file is part of the gitlab Puppet module.
#
#     The gitlab Puppet module is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     The gitlab Puppet module is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with the gitlab Puppet module.  If not, see <http://www.gnu.org/licenses/>.

# [Remember: No empty lines between comments and class definition]
class gitlab (
  $gitlab_url             = undef,
  $relative_url_root      = undef,
  $port                   = undef,
  $enable_https           = false,
  $redirect_http          = false,
  $email_address          = undef,
  $user                   = $::gitlab::params::user,
  $user_home              = $::gitlab::params::user_home,
  $install_gl_shell       = true,
  $gitlab_shell_repo      = $::gitlab::params::gitlab_shell_repo,
  $gitlab_shell_rev       = $::gitlab::params::gitlab_shell_rev,
  $manage_db              = true,
  $db_user                = $::gitlab::params::user,
  $db_name                = $::gitlab::params::db_name,
  $db_host                = undef,
  $db_port                = undef,
  $db_user_password       = 'veryveryunsafe',
  $db_user_passwd_hash    = undef,
  $servername             = $::fqdn,
  $selfsigned_certs       = true,
  $audit_usernames        = false,
  $log_level              = 'INFO',
  $gl_shell_logfile       = undef,
  $gitlab_app_dir         = undef,
  $gitlab_app_repo        = $::gitlab::params::gitlab_app_repo,
  $gitlab_app_rev         = $::gitlab::params::gitlab_app_rev,
  $default_project_limit  = 10,
  $allow_group_creation   = true,
  $allow_name_change      = true,
  $default_theme_id       = 2,
  $project_issues         = true,
  $project_merge_requests = true,
  $project_wiki           = true,
  $project_snippets       = false,
  $project_visibility     = 'private',
  $enable_gravatar        = true,
  $ssh_port               = undef,
  $ssl_cert               = undef,
  $ssl_key                = undef,
  $ssl_ca                 = undef,
  $omniauth               = undef,
  $allow_sso              = false,
  $block_auto_create      = true,
  $shibboleth             = false,
  $signup_enabled         = false,
  $signin_enabled         = true,
  $time_zone              = undef
) inherits gitlab::params {

  require redis
  require nodejs

  validate_bool($install_gl_shell, $manage_db, $enable_https, $selfsigned_certs, $audit_usernames)
  validate_bool($allow_name_change, $allow_group_creation, $enable_gravatar)
  validate_bool($project_snippets, $project_wiki, $project_issues)
  validate_re($project_visibility, ['^private$', '^public$', '^internal$'])

  if ! $enable_https and ($omniauth or $shibboleth) {
    fail('Authentication enabled while HTTPS disabled.')
  }

  $repository_dir = "${user_home}/repositories"
  $satellites_dir = "${user_home}/gitlab-satellites"
  $auth_file      = "${user_home}/.ssh/authorized_keys"
  if $gitlab_app_dir {
    $app_dir = $gitlab_app_dir
  } else {
    $app_dir = "${user_home}/gitlab"
  }
  if $email_address {
    $real_email = $email_address
  } else {
    $real_email = "${user}@${servername}"
  }

  $site_dir = "${app_dir}/public"

  if $port {
    $real_port    = $port
    $port_string = ":${port}"
  } elsif $enable_https {
    $real_port    = '443'
    $port_string = ''
  } else {
    $real_port    = '80'
    $port_string = ''
  }

  if $enable_https {
    $url_protocol = 'https://'
  } else {
    $url_protocol = 'http://'
  }

  if $gitlab_url {
    $real_gitlab_url = $gitlab_url
  } elsif $relative_url_root {
    $real_gitlab_url = "${url_protocol}${servername}${port_string}${relative_url_root}"
  } else  {
    $real_gitlab_url = "${url_protocol}${servername}${port_string}/"
  }

  user{'gitlab':
    ensure     => present,
    name       => $user,
    home       => $user_home,
    password   => '!',
    comment    => 'GitLab services and application user',
    managehome => true,
    shell      => '/bin/bash',
  }

  git::user{$user:
    user_name  => 'GitLab',
    user_email => $real_email,
    require    => User['gitlab'],
  }

  git::config{'git_core_autocrlf':
    config   => 'core.autocrlf',
    value    => 'input',
    provider => 'global',
    user     => $user
  }

  file{'gitlab_home':
    ensure => 'directory',
    path   => $user_home,
    owner  => $user,
    group  => $user,
    mode   => '0755'
  }

  file{'gitlab_repostiories_dir':
    ensure => 'directory',
    path   => $repository_dir,
    owner  => $user,
    group  => $user,
    mode   => '2770',
  }

  file{'gitlab_satellites_dir':
    ensure => 'directory',
    path   => $satellites_dir,
    owner  => $user,
    group  => $user,
    mode   => '0750',
    ignore => ['.git'],
  }

  file{'gitlab_auth_file':
    ensure => 'file',
    path   => $auth_file,
    owner  => $user,
    group  => $user,
    mode   => '0600',
  }

  if $install_gl_shell {
    class{'gitlab::shell::install':
      gitlab_url       => $real_gitlab_url,
      user             => $user,
      user_home        => $user_home,
      repository       => $gitlab_shell_repo,
      revision         => $gitlab_shell_rev,
      repository_dir   => $repository_dir,
      auth_file        => $auth_file,
      selfsigned_certs => $selfsigned_certs,
      audit_usernames  => $audit_usernames,
      log_level        => $log_level,
      gl_shell_logfile => $gl_shell_logfile,
      before           => Ruby::Bundle['gitlab_install'],
    }
  }

  if $manage_db {
    # use a case here if other database providers are ever implemented
    class{'gitlab::db::postgresql':
      db_user             => $db_user,
      db_name             => $db_name,
      db_user_password    => $db_user_password,
      db_user_passwd_hash => $db_user_passwd_hash,
      gitlab_server       => $servername,
      db_host             => $servername,
    }
  }

  class{'gitlab::install':
    app_dir    => $app_dir,
    repository => $gitlab_app_repo,
    revision   => $gitlab_app_rev,
    user       => $user,
  }

  file{'gitlab_app_config':
    ensure  => 'file',
    path    => "${app_dir}/config/gitlab.yml",
    owner   => $user,
    group   => $user,
    mode    => '0640',
    content => template('gitlab/app/gitlab.yml.erb'),
    require => Class['gitlab::install'],
    notify  => [Service['httpd'],Ruby::Rake['gitlab_precompile_assets']],
  }

  file{'gitlab_app_rb_config':
    ensure  => 'file',
    path    => "${app_dir}/config/application.rb",
    owner   => $user,
    group   => $user,
    mode    => '0640',
    content => template('gitlab/app/application.rb.erb'),
    require => Class['gitlab::install'],
    notify  => [Service['httpd'],Ruby::Rake['gitlab_precompile_assets']],
  }

  file{'gitlab_db_config':
    ensure  => 'file',
    path    => "${app_dir}/config/database.yml",
    owner   => $user,
    group   => $user,
    mode    => '0640',
    content => template('gitlab/app/database.yml.erb'),
    require => Class['gitlab::install'],
  }

  file{'gitlab_resque_config':
    ensure  => 'file',
    path    => "${app_dir}/config/resque.yml",
    owner   => $user,
    group   => $user,
    mode    => '0640',
    content => template('gitlab/app/resque.yml.erb'),
    require => Class['gitlab::install'],
  }

  file{'gitlab_etc_default':
    ensure  => 'file',
    path    => '/etc/default/gitlab',
    mode    => '0644',
    content => template('gitlab/app/gitlab_default.erb'),
    require => Class['gitlab::install'],
  }

  file{'gitlab_init_script':
    ensure  => 'file',
    path    => '/etc/init.d/gitlab',
    # owner   => $user,
    # group   => $user,
    mode    => '0755',
    content => template('gitlab/app/gitlab_init.d.erb'),
    require => File['gitlab_etc_default'],
  }

  ruby::bundle{'gitlab_install':
    command     => 'install',
    option      => '--deployment --path=vendor/bundle --without test development mysql aws unicorn',
    environment => ["HOME=${user_home}"],
    cwd         => $app_dir,
    user        => $user,
    # multicore   => '0',
    timeout     => '1200',
    require     => [
      File['gitlab_db_config','gitlab_app_config']
    ]
  }

  ruby::rake{'gitlab_setup':
    task        => 'gitlab:setup',
    environment => ['force=yes',"HOME=${user_home}"],
    bundle      => true,
    refreshonly => true,
    cwd         => $app_dir,
    user        => $user,
    subscribe   => Ruby::Bundle['gitlab_install'],
  }

  if $relative_url_root {
    $precompile_environment = ['force=yes',"HOME=${user_home}","RAILS_RELATIVE_URL_ROOT=${relative_url_root}"]
  } else {
    $precompile_environment = ['force=yes',"HOME=${user_home}"]
  }

  ruby::rake{'gitlab_precompile_assets':
    task        => 'assets:precompile',
    environment => $precompile_environment,
    bundle      => true,
    creates     => "${site_dir}/assets",
    cwd         => $app_dir,
    user        => $user,
    subscribe   => Ruby::Bundle['gitlab_install'],
    notify      => Service['httpd'],
    require     => Ruby::Rake['gitlab_setup'],
  }

  ruby::rake{'gitlab_import_repos':
    task        => 'gitlab:import:repos',
    environment => ["HOME=${user_home}"],
    bundle      => true,
    cwd         => $app_dir,
    user        => $user,
    refreshonly => true,
    require     => Ruby::Rake['gitlab_setup'],
  }

  # Need some clever here to work with systemd when appropriate
  service{'gitlab':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'init',
    require    => File['gitlab_init_script'],
  }

  $vhost_error_docs = [
    {
      'error_code' => '404',
      'document'   => '/404.html'
    },
    {
      'error_code' => '422',
      'document'   => '/422.html'
    },
    {
      'error_code' => '500',
      'document'   => '/500.html'
    },
    {
      'error_code' => '503',
      'document'   => '/deploy.html'
    }
  ]

  $vhost_custom_fragment = "  CustomLog ${::apache::logroot}/gitlab_${servername}_forwarded.log common_forwarded\n  CustomLog ${::apache::logroot}/gitlab_${servername}_access.log combined env=!dontlog\n  CustomLog ${::apache::logroot}/gitlab_${servername}.log combined"

  if $enable_https {
    if $redirect_http {
      apache::vhost{'gitlab_http_redirect':
        servername    => $servername,
        docroot       => $site_dir,
        serveradmin   => $email_address,
        docroot_owner => $user,
        docroot_group => $user,
        port          => '80',
        directories   => {},
        rewrites      => [
          {
            'rewrite_cond' => '%{HTTPS} !=on'
          },
          {
            'rewrite_rule' => '.* https://%{SERVER_NAME}%{REQUEST_URI} [NE,R,L]'
          }
        ],
      }
    }
    if $shibboleth {
      apache::vhost{'gitlab':
        servername            => $servername,
        serveradmin           => $email_address,
        ssl                   => true,
        ssl_cipher            => 'SSLv3:TLSv1:+HIGH:!SSLv2:!MD5:!MEDIUM:!LOW:!EXP:!ADH:!eNULL:!aNULL',
        ssl_cert              => $ssl_cert,
        ssl_key               => $ssl_key,
        ssl_ca                => $ssl_ca,
        docroot               => $site_dir,
        docroot_owner         => $user,
        docroot_group         => $user,
        port                  => $real_port,
        aliases               => [
          {
            alias => '/shibboleth-sp',
            path  => '/usr/share/shibboleth',
          }
        ],
        directories           => [
          {
            path              => '/',
            provider          => 'location',
            allow             => 'from all',
            options           => ['-MultiViews'],
            passenger_enabled => 'on',
          },
          {
            path                  => '/users/auth/shibboleth/callback',
            provider              => 'location',
            auth_type             => 'shibboleth',
            auth_require          => 'valid-user',
            passenger_enabled     => 'on',
            shib_request_settings => ['requireSession 1'],
            shib_use_headers      => 'On',
          },
          {
            path              => '/shibboleth-sp',
            provider          => 'location',
            passenger_enabled => 'off',
            satisfy           => 'any',
          },
          {
            path              => '/Shibboleth.sso',
            provider          => 'location',
            passenger_enabled => 'off',
            sethandler        => 'shib',
          }
        ],
        rewrites              => [
          { 'comment'      => 'Do not rewrite shibboleth requests',
            'rewrite_cond' => [
              '%{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f',
              '%{REQUEST_URI} !/Shibboleth.sso',
              '%{REQUEST_URI} !/shibboleth-sp',
            ],
#            'rewrite_rule'  => ['.* https://%{SERVER_NAME}%{REQUEST_URI} [QSA]'],
          }
        ],
        request_headers       => ["set X_FORWARDED_PROTO 'https'"],
        error_documents       => $vhost_error_docs,
        error_log_file        => "gitlab.${servername}.log",
        custom_fragment       => $vhost_custom_fragment,
        allow_encoded_slashes => 'nodecode',
        require               => [
          Ruby::Rake['gitlab_precompile_assets'],
          Service['gitlab'],
        ],
      }
    } else {
      apache::vhost{'gitlab':
        servername            => $servername,
        serveradmin           => $email_address,
        ssl                   => true,
        ssl_cipher            => 'SSLv3:TLSv1:+HIGH:!SSLv2:!MD5:!MEDIUM:!LOW:!EXP:!ADH:!eNULL:!aNULL',
        ssl_cert              => $ssl_cert,
        ssl_key               => $ssl_key,
        ssl_ca                => $ssl_ca,
        docroot               => $site_dir,
        docroot_owner         => $user,
        docroot_group         => $user,
        port                  => $real_port,
        directories           => [
          { path     => $site_dir,
            provider => 'location',
            allow    => 'from all',
            options  => ['-MultiViews'],
          }
        ],
        error_documents       => $vhost_error_docs,
        error_log_file        => "gitlab_${servername}_error.log",
        custom_fragment       => $vhost_custom_fragment,
        allow_encoded_slashes => 'nodecode',
        require               => [
          Ruby::Rake['gitlab_precompile_assets'],
          Service['gitlab'],
        ],
      }
    }
  } else {
    apache::vhost{'gitlab':
      servername            => $servername,
      serveradmin           => $email_address,
      docroot               => $site_dir,
      docroot_owner         => $user,
      docroot_group         => $user,
      port                  => $real_port,
      directories           => [
        {
          path     => $site_dir,
          provider => 'location',
          allow    => 'from all',
          options  => ['-MultiViews'],
        }
      ],
      error_documents       => $vhost_error_docs,
      error_log_file        => "gitlab_${servername}_error.log",
      allow_encoded_slashes => 'nodecode',
      custom_fragment       => $vhost_custom_fragment,
      require               => [
        Ruby::Rake['gitlab_precompile_assets'],
        Service['gitlab'],
      ],
    }
  }
}
