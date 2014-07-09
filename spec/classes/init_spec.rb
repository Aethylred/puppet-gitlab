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
      it { should contain_class('gitlab::shell::install').with(
        'gitlab_url'        => 'http://localhost/',
        'user'              => 'git',
        'user_home'         => '/home/git',
        'repository'        => 'https://gitlab.com/gitlab-org/gitlab-shell.git',
        'revision'          => 'v1.8.0',
        'repository_dir'    => '/home/git/repositories',
        'auth_file'         => '/home/git/.ssh/authorized_keys',
        'selfsigned_certs'  => true,
        'audit_usernames'   => nil,
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
      it { should contain_class('gitlab::shell::install').with(
        'user'            => 'nobody',
        'user_home'       => '/path/to/home',
        'repository_dir'  => '/path/to/home/repositories',
        'auth_file'       => '/path/to/home/.ssh/authorized_keys'
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
