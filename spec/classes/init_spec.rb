require 'spec_helper'
describe 'gitlab', :type => :class do
  on_supported_os.each do |os, facts|
    if os != 'ubuntu-14.04-x86_64' then next end
    context "on #{os}" do
      let(:facts) do
        facts.merge({
            :fqdn                   => 'test.example.org',
          })
      end
      let :pre_condition do
        "include redis\ninclude apache\ninclude postgresql::server"
      end
      describe 'with no parameters' do
        it { should contain_class('gitlab::params') }
        it { should contain_user('gitlab').with(
          'ensure'        => 'present',
          'name'          => 'git',
          'home'          => '/home/git',
          'password'      => '!',
          'comment'       => 'GitLab services and application user',
          'managehome'    => true,
          'shell'         => '/bin/bash'
        ) }
        it { should contain_git__user('git').with(
          'user_name'   => 'GitLab',
          'user_email'  => 'git@test.example.org'
        ) }
        it { should contain_git__config('git_core_autocrlf').with(
          'config'   => 'core.autocrlf',
          'value'    => 'input',
          'provider' => 'global',
          'user'     => 'git'
        ) }
        it { should contain_file('gitlab_home').with(
          'ensure'  => 'directory',
          'path'    => '/home/git',
          'owner'   => 'git',
          'group'   => 'git',
          'recurse' => true
        ) }
        it { should contain_file('gitlab_repostiories_dir').with(
          'ensure'  => 'directory',
          'path'    => '/home/git/repositories',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '2770'
        ) }
        it { should contain_file('gitlab_satellites_dir').with(
          'ensure'  => 'directory',
          'path'    => '/home/git/gitlab-satellites',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '0750',
          'ignore'  => ['.git']
        ) }
        it { should contain_file('gitlab_auth_file').with(
          'ensure'  => 'file',
          'path'    => '/home/git/.ssh/authorized_keys',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '0600'
        ) }
        it { should contain_class('gitlab::shell::install').with(
          'gitlab_url'        => 'http://test.example.org/',
          'user'              => 'git',
          'user_home'         => '/home/git',
          'repository'        => 'https://github.com/gitlabhq/gitlab-shell.git',
          'revision'          => 'v2.0.1',
          'repository_dir'    => '/home/git/repositories',
          'auth_file'         => '/home/git/.ssh/authorized_keys',
          'selfsigned_certs'  => true,
          'audit_usernames'   => false,
          'log_level'         => 'INFO',
          'gl_shell_logfile'  => nil
        ) }
        it { should contain_class('gitlab::db::postgresql').with(
          'db_user'             => 'git',
          'db_name'             => 'gitlab',
          'db_user_password'    => 'veryveryunsafe',
          'db_user_passwd_hash' => nil,
          'gitlab_server'       => 'test.example.org',
          'db_host'             => 'test.example.org'
        )}
        it { should contain_class('gitlab::install').with(
          'app_dir'     => '/home/git/gitlab',
          'repository'  => 'https://github.com/gitlabhq/gitlabhq.git',
          'revision'    => '7-4-stable',
          'user'        => 'git'
        ) }
        it { should contain_file('gitlab_app_config').with(
          'ensure'  => 'file',
          'path'    => '/home/git/gitlab/config/gitlab.yml',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '0640',
          'require' => 'Class[Gitlab::Install]'
        ) }
        it { should contain_file('gitlab_app_rb_config').with(
          'ensure'  => 'file',
          'path'    => '/home/git/gitlab/config/application.rb',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '0640',
          'require' => 'Class[Gitlab::Install]'
        ) }
        it { should contain_file('gitlab_db_config').with(
          'ensure'  => 'file',
          'path'    => '/home/git/gitlab/config/database.yml',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '0640',
          'require' => 'Class[Gitlab::Install]'
        ) }
        it { should contain_file('gitlab_etc_default').with(
          'ensure'  => 'file',
          'path'    => '/etc/default/gitlab',
          'mode'    => '0644',
          'require' => 'Class[Gitlab::Install]'
        ) }
        it { should contain_file('gitlab_init_script').with(
          'ensure'  => 'file',
          'path'    => '/etc/init.d/gitlab',
          'owner'   => 'git',
          'group'   => 'git',
          'mode'    => '0744',
          'require' => 'File[gitlab_etc_default]'
        ) }
        it { should contain_ruby__bundle('gitlab_install').with(
          'command' => 'install',
          'option'  => '--deployment --path=vendor/bundle --without test development mysql aws unicorn',
          'cwd'     => '/home/git/gitlab',
          'user'    => 'git'
        ) }
        it { should contain_ruby__rake('gitlab_import_repos').with(
          'task'        => 'gitlab:import:repos',
          'environment' => ['HOME=/home/git'],
          'bundle'      => true,
          'refreshonly' => true,
          'cwd'         => '/home/git/gitlab',
          'user'        => 'git',
          'require'     => ['Ruby::Rake[gitlab_setup]','Class[Ruby]']
        ) }
        it { should contain_ruby__rake('gitlab_setup').with(
          'task'        => 'gitlab:setup',
          'environment' => ['force=yes','HOME=/home/git'],
          'bundle'      => true,
          'refreshonly' => true,
          'cwd'         => '/home/git/gitlab',
          'user'        => 'git',
          'subscribe'   => 'Ruby::Bundle[gitlab_install]'
        ) }
        it { should contain_ruby__rake('gitlab_precompile_assets').with(
          'task'        => 'assets:precompile',
          'environment' => ['force=yes','HOME=/home/git'],
          'bundle'      => true,
          # 'creates'     => '/home/git/gitlab/public/assets',
          'cwd'         => '/home/git/gitlab',
          'user'        => 'git',
          'subscribe'   => 'Ruby::Bundle[gitlab_install]',
          'notify'      => 'Service[httpd]'
        ) }
        it { should contain_service('gitlab').with(
          'ensure'      => 'running',
          'enable'      => true,
          'hasstatus'   => true,
          'hasrestart'  => true,
          'require'     => 'File[gitlab_init_script]'
        ) }
        it { should contain_apache__vhost('gitlab').with(
          'servername'      => 'test.example.org',
          'serveradmin'     => nil,
          'docroot'         => '/home/git/gitlab/public',
          'docroot_owner'   => 'git',
          'docroot_group'   => 'git',
          'port'            => '80',
          'error_documents' => [
            {'error_code' => '404', 'document' => '/404.html'},
            {'error_code' => '422', 'document' => '/422.html'},
            {'error_code' => '500', 'document' => '/500.html'},
            {'error_code' => '503', 'document' => '/deploy.html'}
          ],
          'error_log_file'  => 'gitlab.test.example.org.log',
          'custom_fragment' => "  CustomLog /var/log/apache2/gitlab_test.example.org_forwarded.log common_forwarded\n  CustomLog /var/log/apache2/gitlab_test.example.org_access.log combined env=!dontlog\n  CustomLog /var/log/apache2/gitlab_test.example.org.log combined",
          'allow_encoded_slashes' => 'nodecode',
          'require'         => ['Ruby::Rake[gitlab_precompile_assets]','Service[gitlab]']
        ) }
        it { should contain_apache__vhost('gitlab').with_directories(
          {
            'provider'  => 'location',
            'path'      => '/home/git/gitlab/public',
            'allow'     => 'from all',
            'options'   => ['-MultiViews'],
          }
        ) }
        # Verify contents of gitlab_app_config
        it { should contain_file('gitlab_app_config').with_content(
          %r{^# This file is managed by Puppet, changes may be overwritten.$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    host: test.example.org$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    port: 80$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    https: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    # relative_url_root: /gitlab$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    relative_url_root: .*$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    time_zone: .*$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    user: git$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    email_from: git@test.example.org$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_projects_limit: 10$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_can_create_group: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    username_changing_enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_theme: 2 # default: 2$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_projects_features:$\s^      issues: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      merge_requests: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      wiki: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      snippets: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      visibility_level: "private"$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  gravatar:$\s^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  gitlab_shell:$\s^    path: /home/git/gitlab-shell/$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    repos_path: /home/git/repositories$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    hooks_path: /home/git/gitlab-shell/hooks/$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    # ssh_port: 22$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    allow_single_sign_on: false$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    allow_single_sign_on: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    block_auto_created_users: true$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    block_auto_created_users: false$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^      - \{ name: 'github', app_id: '*.'$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^      - \{ name: 'twitter', app_id: '*.'$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^      - \{ name: 'google_oauth2', app_id: '*.'$}
        ) }
        # Verify contents of gitlab_db_config
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  database: gitlab$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  username: git$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  password: veryveryunsafe$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  # host: localhost$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  # port: 5432$}
        ) }
        # Verify contents of gitlab_app_rb_config
        it { should contain_file('gitlab_app_rb_config').with_content(
          %r{^    # config.relative_url_root = "/gitlab"$}
        ) }
        it { should contain_file('gitlab_app_rb_config').without_content(
          %r{^    config.relative_url_root = .*$}
        ) }
        it { should contain_file('gitlab_app_rb_config').without_content(
          %r{^    config.time_zone = .*$}
        ) }
        # Verify contents of gitlab_etc_default
        it { should contain_file('gitlab_etc_default').with_content(
          %r{^app_user="git"$}
        ) }
        it { should contain_file('gitlab_etc_default').with_content(
          %r{^app_root="/home/git/gitlab"$}
        ) }
        # Verify contents of gitlab_init_script
        it { should contain_file('gitlab_init_script').with_content(
          %r{^app_user="git"$}
        ) }
        it { should contain_file('gitlab_init_script').with_content(
          %r{^app_root="/home/git/gitlab"$}
        ) }
      end
      describe 'when not managing the gitlab shell install' do
        let :params do
          {
            :install_gl_shell => false
          }
        end
        it { should_not contain_class('gitlab::shell::install') }
      end
      describe 'when not managing the gitlab database install' do
        let :params do
          {
            :manage_db => false
          }
        end
        it { should_not contain_class('gitlab::db::postgresql') }
      end
      describe 'when given a user name and home directory' do
        let :params do
          {
            :user       => 'nobody',
            :user_home  => '/path/to/home'
          }
        end
        it { should contain_user('gitlab').with(
          'name'  => 'nobody',
          'home'  => '/path/to/home'
        ) }
        it { should contain_git__user('nobody').with(
          'user_email'  => 'nobody@test.example.org'
        ) }
        it { should contain_git__config('git_core_autocrlf').with(
          'user'     => 'nobody'
        ) }
        it { should contain_file('gitlab_home').with(
          'path'    => '/path/to/home',
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_file('gitlab_repostiories_dir').with(
          'path'    => '/path/to/home/repositories',
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_file('gitlab_auth_file').with(
          'path'    => '/path/to/home/.ssh/authorized_keys',
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_class('gitlab::shell::install').with(
          'user'            => 'nobody',
          'user_home'       => '/path/to/home',
          'repository_dir'  => '/path/to/home/repositories',
          'auth_file'       => '/path/to/home/.ssh/authorized_keys'
        ) }
        it { should contain_class('gitlab::install').with(
          'user'    => 'nobody',
          'app_dir' => '/path/to/home/gitlab'
        ) }
        it { should contain_file('gitlab_app_config').with(
          'path'    => '/path/to/home/gitlab/config/gitlab.yml',
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_file('gitlab_app_rb_config').with(
          'path'    => '/path/to/home/gitlab/config/application.rb',
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_file('gitlab_db_config').with(
          'path'    => '/path/to/home/gitlab/config/database.yml',
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_file('gitlab_init_script').with(
          'owner'   => 'nobody',
          'group'   => 'nobody'
        ) }
        it { should contain_ruby__bundle('gitlab_install').with(
          'cwd'     => '/path/to/home/gitlab',
          'user'    => 'nobody'
        ) }
        it { should contain_ruby__rake('gitlab_import_repos').with(
          'environment' => ['HOME=/path/to/home'],
          'cwd'         => '/path/to/home/gitlab',
          'user'        => 'nobody'
        ) }
        it { should contain_ruby__rake('gitlab_setup').with(
          'environment' => ['force=yes','HOME=/path/to/home'],
          'cwd'         => '/path/to/home/gitlab',
          'user'        => 'nobody'
        ) }
        it { should contain_ruby__rake('gitlab_precompile_assets').with(
          'environment' => ['force=yes','HOME=/path/to/home'],
          # 'creates'     => '/path/to/home/gitlab/public/assets',
          'cwd'         => '/path/to/home/gitlab',
          'user'        => 'nobody'
        ) }
        it { should contain_apache__vhost('gitlab').with(
          'docroot'         => '/path/to/home/gitlab/public',
          'docroot_owner'   => 'nobody',
          'docroot_group'   => 'nobody',
          'directories'     => {
            'path'      => '/path/to/home/gitlab/public',
              'provider'  => 'location',
              'allow'     => 'from all',
              'options'   => ['-MultiViews'],
          }
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  gitlab_shell:$\s^    path: /path/to/home/gitlab-shell/$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    repos_path: /path/to/home/repositories$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    hooks_path: /path/to/home/gitlab-shell/hooks/$}
        ) }
        # Verify contents of gitlab_etc_default
        it { should contain_file('gitlab_etc_default').with_content(
          %r{^app_user="nobody"$}
        ) }
        it { should contain_file('gitlab_etc_default').with_content(
          %r{^app_root="/path/to/home/gitlab"$}
        ) }
        # Verify contents of gitlab_init_script
        it { should contain_file('gitlab_init_script').with_content(
          %r{^app_user="nobody"$}
        ) }
        it { should contain_file('gitlab_init_script').with_content(
          %r{^app_root="/path/to/home/gitlab"$}
        ) }
      end
      describe 'when given parameters to pass through to gitlab shell' do
        let :params do
          {
            :gitlab_url         => 'http://gitlab.example.org/',
            :gitlab_shell_repo  => 'https://git.example.org/repo.git',
            :gitlab_shell_rev   => 'test',
            :selfsigned_certs   => false,
            :audit_usernames    => true,
            :log_level          => 'WARN',
            :gl_shell_logfile   => '/path/to/log',
          }
        end
        it { should contain_class('gitlab::shell::install').with(
          'gitlab_url'        => 'http://gitlab.example.org/',
          'repository'        => 'https://git.example.org/repo.git',
          'revision'          => 'test',
          'selfsigned_certs'  => false,
          'audit_usernames'   => true,
          'log_level'         => 'WARN',
          'gl_shell_logfile'  => '/path/to/log'
        ) }
      end
      describe 'when given parameters that configure the Ruby application' do
        let :params do
          {
            :relative_url_root => '/git',
            :time_zone         => 'Pacific/Auckland',
          }
        end
        # Verify contents of gitlab_app_rb_config
        it { should contain_file('gitlab_app_rb_config').without_content(
          %r{^    # config.relative_url_root = "/gitlab"$}
        ) }
        it { should contain_file('gitlab_app_rb_config').with_content(
          %r{^    config.relative_url_root = "/git"}
        ) }
        it { should contain_file('gitlab_app_rb_config').with_content(
          %r{^    config.time_zone = 'Pacific/Auckland'$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    time_zone: 'Pacific/Auckland'$}
        ) }
      end
      describe 'when given database configuration details' do
        let :params do
          {
            :db_user              => 'nobody',
            :db_name              => 'gitlab_test',
            :db_host              => 'db.example.org',
            :db_port              => '4466',
            :db_user_password     => 'stillinsecure',
            :db_user_passwd_hash  => 'this is not really a hash',
            :servername           => 'gitlab.example.com',
          }
        end
        it { should contain_class('gitlab::db::postgresql').with(
          'db_user'             => 'nobody',
          'db_name'             => 'gitlab_test',
          'db_user_password'    => 'stillinsecure',
          'db_user_passwd_hash' => 'this is not really a hash',
          'gitlab_server'       => 'gitlab.example.com',
          'db_host'             => 'gitlab.example.com'
        )}
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  database: gitlab_test$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  username: nobody$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  password: stillinsecure$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  host: db.example.org$}
        ) }
        it { should contain_file('gitlab_db_config').without_content(
          %r{^  # host: localhost$}
        ) }
        it { should contain_file('gitlab_db_config').with_content(
          %r{^  port: 4466$}
        ) }
        it { should contain_file('gitlab_db_config').without_content(
          %r{^  # port: 5432$}
        ) }
      end
      describe 'when given parameters to pass through to gitlab application install' do
        let :params do
          {
            :gitlab_app_repo  => 'https://git.example.org/repo.git',
            :gitlab_app_rev   => 'test',
            :gitlab_app_dir   => '/path/to/app',
          }
        end
        it { should contain_class('gitlab::install').with(
          'app_dir'     => '/path/to/app',
          'repository'  => 'https://git.example.org/repo.git',
          'revision'    => 'test'
        ) }
      end
      describe 'when configuring the application server' do
        let :params do
          {
            :servername         => 'git.somewhere.org',
            :port               => '8080',
            :enable_https       => true,
            :redirect_http      => true,
            :relative_url_root  => '/',
            :email_address      => 'admin@somewhere.org',
            :ssl_cert           => '/path/to/cert.crt',
            :ssl_key            => '/path/to/key.pem',
            :ssl_ca             => '/path/to/ca.crt',
          }
        end
        it { should contain_git__user('git').with(
          'user_email'  => 'admin@somewhere.org'
        ) }
        it { should contain_apache__vhost('gitlab_http_redirect').with(
          'servername'      => 'git.somewhere.org',
          'docroot'         => '/home/git/gitlab/public',
          'serveradmin'     => 'admin@somewhere.org',
          'docroot_owner'   => 'git',
          'docroot_group'   => 'git',
          'port'            => '80',
          'directories'     => {},
          'rewrites'        => [
            {'rewrite_cond'  => '%{HTTPS} !=on'},
            {'rewrite_rule'  => '.* https://%{SERVER_NAME}%{REQUEST_URI} [NE,R,L]'}
          ]
        ) }
        it { should contain_apache__vhost('gitlab').with(
          'servername'      => 'git.somewhere.org',
          'serveradmin'     => 'admin@somewhere.org',
          'ssl'             => true,
          'ssl_cipher'      => 'SSLv3:TLSv1:+HIGH:!SSLv2:!MD5:!MEDIUM:!LOW:!EXP:!ADH:!eNULL:!aNULL',
          'ssl_cert'        => '/path/to/cert.crt',
          'ssl_key'         => '/path/to/key.pem',
          'ssl_ca'          => '/path/to/ca.crt',
          'docroot'         => '/home/git/gitlab/public',
          'docroot_owner'   => 'git',
          'docroot_group'   => 'git',
          'port'            => '8080',
          'directories'     => {
            'path'      => '/home/git/gitlab/public',
            'provider'  => 'location',
            'allow'     => 'from all',
            'options'   => ['-MultiViews'],
          },
          'error_documents' => [
            {'error_code' => '404', 'document' => '/404.html'},
            {'error_code' => '422', 'document' => '/422.html'},
            {'error_code' => '500', 'document' => '/500.html'},
            {'error_code' => '503', 'document' => '/deploy.html'}
          ],
          'error_log_file'  => 'gitlab.git.somewhere.org.log',
          'custom_fragment' => "  CustomLog /var/log/apache2/gitlab_git.somewhere.org_forwarded.log common_forwarded\n  CustomLog /var/log/apache2/gitlab_git.somewhere.org_access.log combined env=!dontlog\n  CustomLog /var/log/apache2/gitlab_git.somewhere.org.log combined",
          'allow_encoded_slashes' => 'nodecode',
          'require'         => ['Ruby::Rake[gitlab_precompile_assets]','Service[gitlab]']
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    host: git.somewhere.org$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    port: 8080$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    https: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    relative_url_root: /$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    email_from: admin@somewhere.org$}
        ) }
      end
      describe 'when configuring user defaults' do
        let :params do
          {
            :default_project_limit  => '25',
            :allow_group_creation   => false,
            :allow_name_change      => false,
            :default_theme_id       => '3',
          }
        end
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_projects_limit: 25$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_can_create_group: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    username_changing_enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_theme: 3 # default: 2$}
        ) }
      end
      describe 'when configuring project defaults' do
        let :params do
          {
            :project_issues         => false,
            :project_merge_requests => false,
            :project_wiki           => false,
            :project_snippets       => true,
            :project_visibility     => 'public',
          }
        end
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    default_projects_features:$\s^      issues: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      merge_requests: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      wiki: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      snippets: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      visibility_level: "public"$}
        ) }
      end
      describe 'when disabling gravatar' do
        let :params do
          {
            :enable_gravatar => false,
          }
        end
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  gravatar:$\s^    enabled: false$}
        ) }
      end
      describe 'when setting a custom SSH port' do
        let :params do
          {
            :ssh_port => '2222',
          }
        end
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    # ssh_port: 22$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    ssh_port: 2222$}
        ) }
      end
      describe 'when setting GitHub as an OmniAuth provider' do
        let :params do
          {
            :enable_https  => true,
            :omniauth      => [
              { 'provider'    => 'github',
                'app_id'      => 'YOURIDHERE',
                'app_secret'  => 'YOURHASHHERE'
              }
            ]
          }
        end
        it { should contain_file('gitlab_app_config').without_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'github', app_id: 'YOURIDHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          app_secret: 'YOURHASHHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          args: \{ scope: 'user:email' \} \}$}
        ) }
      end
      describe 'when setting Twitter as an OmniAuth provider' do
        let :params do
          {
            :enable_https  => true,
            :omniauth      => [
              { 'provider'    => 'twitter',
                'app_id'      => 'YOURIDHERE',
                'app_secret'  => 'YOURHASHHERE'
              }
            ]
          }
        end
        it { should contain_file('gitlab_app_config').without_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'twitter', app_id: 'YOURIDHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          app_secret: 'YOURHASHHERE' \}$}
        ) }
      end
      describe 'when setting Google as an OmniAuth provider' do
        let :params do
          {
            :enable_https  => true,
            :omniauth      => [
              { 'provider'    => 'google',
                'app_id'      => 'YOURIDHERE',
                'app_secret'  => 'YOURHASHHERE'
              }
            ]
          }
        end
        it { should contain_file('gitlab_app_config').without_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'google_oauth2', app_id: 'YOURIDHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          app_secret: 'YOURHASHHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          args: \{ access_type: 'offline', approval_prompt: '' \} \}$}
        ) }
      end
      describe 'when setting Shibboleth as an OmniAuth provider' do
        let :params do
          {
            :enable_https => true,
            :shibboleth   => true
          }
        end
        it { should contain_apache__vhost('gitlab').with_aliases(
          {
            'path'  => '/usr/share/shibboleth',
            'alias' => '/shibboleth-sp',
          }
        ) }
        it { should contain_apache__vhost('gitlab').with_rewrites(
          {
            'comment'      => 'Do not rewrite shibboleth requests',
            'rewrite_cond' => [
              '%{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f',
              '%{REQUEST_URI} !/Shibboleth.sso',
              '%{REQUEST_URI} !/shibboleth-sp',
            ],
          }
        ) }
        it { should contain_apache__vhost('gitlab').with_directories(
          [
            {
              'path'              => '/',
              'provider'          => 'location',
              'allow'             => 'from all',
              'options'           => ['-MultiViews'],
              'passenger_enabled' => 'on',
            },
            {
              'path'                  => '/users/auth/shibboleth/callback',
              'provider'              => 'location',
              'auth_type'             => 'shibboleth',
              'auth_require'          => 'valid-user',
              'passenger_enabled'     => 'on',
              'shib_request_settings' => ['requireSession 1'],
              'shib_use_headers'      => 'On',
            },
            {
              'path'              => '/shibboleth-sp',
              'provider'          => 'location',
              'passenger_enabled' => 'off',
              'satisfy'           => 'any',
            },
            {
              'path'              => '/Shibboleth.sso',
              'provider'          => 'location',
              'passenger_enabled' => 'off',
              'sethandler'        => 'shib',
            }
          ]
        ) }
        it { should contain_apache__vhost('gitlab').with(
          'servername'      => 'test.example.org',
          'serveradmin'     => nil,
          'docroot'         => '/home/git/gitlab/public',
          'docroot_owner'   => 'git',
          'docroot_group'   => 'git',
          'port'            => '443',
          'ssl'                   => true,
          'ssl_cipher'            => 'SSLv3:TLSv1:+HIGH:!SSLv2:!MD5:!MEDIUM:!LOW:!EXP:!ADH:!eNULL:!aNULL',
          'error_documents' => [
            {'error_code' => '404', 'document' => '/404.html'},
            {'error_code' => '422', 'document' => '/422.html'},
            {'error_code' => '500', 'document' => '/500.html'},
            {'error_code' => '503', 'document' => '/deploy.html'}
          ],
          'error_log_file'  => 'gitlab.test.example.org.log',
          'custom_fragment' => "  CustomLog /var/log/apache2/gitlab_test.example.org_forwarded.log common_forwarded\n  CustomLog /var/log/apache2/gitlab_test.example.org_access.log combined env=!dontlog\n  CustomLog /var/log/apache2/gitlab_test.example.org.log combined",
          'allow_encoded_slashes' => 'nodecode',
          'require'         => ['Ruby::Rake[gitlab_precompile_assets]','Service[gitlab]']
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'shibboleth',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^            'shib_session_id_field': "HTTP_SHIB_SESSION_ID",$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^            'shib_application_id_field': "HTTP_SHIB_APPLICATION_ID",$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^            'uid_field': 'HTTP_EPPN',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^            'name_field': 'HTTP_CN',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^            'info_fields': \{ 'email': 'HTTP_MAIL'\}$}
        ) }
      end
      describe 'when setting multiple OmniAuth providers' do
        let :params do
          {
            :enable_https  => true,
            :omniauth      => [
              { 'provider'    => 'google',
                'app_id'      => 'YOURGOOGLEIDHERE',
                'app_secret'  => 'YOURGOOGLEHASHHERE'
              },
              { 'provider'    => 'twitter',
                'app_id'      => 'YOURTWITTERIDHERE',
                'app_secret'  => 'YOURTWITTERHASHHERE'
              },
              { 'provider'    => 'github',
                'app_id'      => 'YOURGITHUBIDHERE',
                'app_secret'  => 'YOURGITHUBHASHHERE'
              }
            ]
          }
        end
        it { should contain_file('gitlab_app_config').without_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^  omniauth:$\n^    # Allow login via Twitter, Google, etc. using OmniAuth providers$\n^    enabled: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'google_oauth2', app_id: 'YOURGOOGLEIDHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          app_secret: 'YOURGOOGLEHASHHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          args: \{ access_type: 'offline', approval_prompt: '' \} \}$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'twitter', app_id: 'YOURTWITTERIDHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          app_secret: 'YOURTWITTERHASHHERE' \}$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^      - \{ name: 'github', app_id: 'YOURGITHUBIDHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          app_secret: 'YOURGITHUBHASHHERE',$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^          args: \{ scope: 'user:email' \} \}$}
        ) }
      end
      describe 'when changing user creation behaviour' do
        let :params do
          {
            :allow_sso          => true,
            :block_auto_create  => false
          }
        end
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    allow_single_sign_on: false$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    allow_single_sign_on: true$}
        ) }
        it { should contain_file('gitlab_app_config').without_content(
          %r{^    block_auto_created_users: true$}
        ) }
        it { should contain_file('gitlab_app_config').with_content(
          %r{^    block_auto_created_users: false$}
        ) }
      end
    end
  end

  context 'on a RedHat OS' do
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :fqdn                   => 'test.example.org',
      }
    end
    it { should raise_error(Puppet::Error, /The GitLab Puppet module does not support RedHat family of operating systems/) }
  end

  context 'on an Unknown OS' do
    let :facts do
      {
        :osfamily               => 'Unknown',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :fqdn                   => 'test.example.org',
      }
    end
    it { should raise_error(Puppet::Error, /The GitLab Puppet module does not support Unknown family of operating systems/) }
  end

end
