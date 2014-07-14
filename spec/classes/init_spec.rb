require 'spec_helper'
describe 'gitlab', :type => :class do
  context 'on a Debian OS' do
    let :facts do
      {
        :osfamily       => 'Debian',
        :concat_basedir => '/dne',
        :fqdn           => 'test.example.org',
      }
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
      it { should contain_class('gitlab::shell::install').with(
        'gitlab_url'        => 'http://localhost/',
        'user'              => 'git',
        'user_home'         => '/home/git',
        'repository'        => 'https://gitlab.com/gitlab-org/gitlab-shell.git',
        'revision'          => 'v1.9.6',
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
        'repository'  => 'https://gitlab.com/gitlab-org/gitlab-ce.git',
        'revision'    => '7-0-stable',
        'user'        => 'git'
      ) }
      it { should contain_file('gitlab_app_config').with(
        'ensure'  => 'file',
        'path'    => '/home/git/gitlab/config/gitlab.yml',
        'owner'   => 'git',
        'group'   => 'git',
        'require' => 'Class[Gitlab::Install]'
      ) }
      it { should contain_file('gitlab_db_config').with(
        'ensure'  => 'file',
        'path'    => '/home/git/gitlab/config/database.yml',
        'owner'   => 'git',
        'group'   => 'git',
        'require' => 'Class[Gitlab::Install]'
      ) }
      it { should contain_ruby__bundle('gitlab_install').with(
        'command' => 'install',
        'option'  => '--deployment',
        'cwd'     => '/home/git/gitlab',
        'user'    => 'git'
      ) }
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
        %r{^    relative_url_root: /gitlab$}
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
      it { should contain_file('gitlab_db_config').with(
        'path'    => '/path/to/home/gitlab/config/database.yml',
        'owner'   => 'nobody',
        'group'   => 'nobody'
      ) }
      it { should contain_ruby__bundle('gitlab_install').with(
        'cwd'     => '/path/to/home/gitlab',
        'user'    => 'nobody'
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
          :relative_url_root  => '/',
          :email_address      => 'admin@somewhere.org',
        }
      end
      it { should contain_git__user('git').with(
        'user_email'  => 'admin@somewhere.org'
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
  end

  context 'on a RedHat OS' do
    let :facts do
      {
        :osfamily       => 'RedHat',
        :concat_basedir => '/dne',
      }
    end
    it do
      expect {
        should contain_class('gitlab::params')
      }.to raise_error(Puppet::Error, /The GitLab Puppet module does not support RedHat family of operating systems/)
    end
  end

    context 'on an Unknown OS' do
    let :facts do
      {
        :osfamily       => 'Unknown',
        :concat_basedir => '/dne',
      }
    end
    it do
      expect {
        should contain_class('gitlab::params')
      }.to raise_error(Puppet::Error, /The GitLab Puppet module does not support Unknown family of operating systems/)
    end
  end

end
