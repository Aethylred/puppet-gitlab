require 'spec_helper'
describe 'gitlab::shell::install', :type => :class do
  context 'on a Debian OS' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :fqdn                   => 'test.example.org',
      }
    end
    describe 'with default gitlab (disable shell install so test can redeclare)' do
      let :pre_condition do
        "class {'gitlab': install_gl_shell => false }\ninclude redis\ninclude apache"
      end
      describe 'with no parameters' do
        it { should contain_class('gitlab::params') }
        it { should contain_vcsrepo('gitlab-shell').with(
          'ensure'    => 'present',
          'path'      => '/home/git/gitlab-shell',
          'provider'  => 'git',
          'user'      => 'git',
          'source'    => 'https://gitlab.com/gitlab-org/gitlab-shell.git',
          'revision'  => 'v1.9.6',
          'require'   => 'User[gitlab]'
        ) }
        it { should contain_file('gitlab-shell-config').with(
          'ensure'  => 'file',
          'path'    => '/home/git/gitlab-shell/config.yml',
          'owner'   => 'git',
          'group'   => 'git',
          'require' => 'Vcsrepo[gitlab-shell]'
        )}
        it { should contain_exec('gitlab_shell_install').with(
          'cwd'         => '/home/git',
          'user'        => 'git',
          'command'     => '/home/git/gitlab-shell/bin/install',
          'subscribe'   => 'File[gitlab-shell-config]',
          'refreshonly' => true
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^user: git$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^gitlab_url: "http://test.example.org/"$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^  self_signed_cert: true$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^repos_path: "/home/git/repositories"$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^auth_file: "/home/git/.ssh/authorized_keys"$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^log_level: INFO$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^audit_usernames: false$}
        ) }
        it {should contain_file('gitlab-shell-config').without_content(
          %r{^  self_signed_cert: false$}
        ) }
        it {should contain_file('gitlab-shell-config').without_content(
          %r{^log_file: .*$}
        ) }
        it {should contain_file('gitlab-shell-config').without_content(
          %r{^audit_usernames: true$}
        ) }
      end
      describe 'when given a user' do
        let :params do
          {
            :user => 'notgit'
          }
        end
        it { should contain_vcsrepo('gitlab-shell').with(
          'user'     => 'notgit'
        ) }
        it { should contain_file('gitlab-shell-config').with(
          'owner'   => 'notgit',
          'group'   => 'notgit'
        )}
        it { should contain_exec('gitlab_shell_install').with(
          'user'    => 'notgit'
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^user: notgit$}
        ) }
        it {should contain_file('gitlab-shell-config').without_content(
          %r{^user: git$}
        ) }
      end
      describe 'when given a user home directory' do
        let :params do
          {
            :user_home => '/path/to/home'
          }
        end
        it { should contain_vcsrepo('gitlab-shell').with(
          'path'     => '/path/to/home/gitlab-shell'
        ) }
        it { should contain_file('gitlab-shell-config').with(
          'path'    => '/path/to/home/gitlab-shell/config.yml'
        )}
        it { should contain_exec('gitlab_shell_install').with(
          'cwd'         => '/path/to/home'
        ) }
      end
      describe 'when given an alternative repository' do
        let :params do
          {
            :repository => 'https://git.example.org/repo.git'
          }
        end
        it { should contain_vcsrepo('gitlab-shell').with(
          'source'    => 'https://git.example.org/repo.git'
        ) }
      end
      describe 'when given a repository reference' do
        let :params do
          {
            :revision => 'test'
          }
        end
        it { should contain_vcsrepo('gitlab-shell').with(
          'revision'  => 'test'
        ) }
      end
      describe 'when given parameters for the config file' do
        let :params do
          {
            :repository_dir   => '/path/to/dir',
            :auth_file        => '/path/to/file',
            :selfsigned_certs => false,
            :audit_usernames  => true,
            :log_level        => 'WARN',
            :gl_shell_logfile => '/path/to/log/file.log'
          }
        end
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^  self_signed_cert: false$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^repos_path: "/path/to/dir"$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^auth_file: "/path/to/file"$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^log_level: WARN$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^audit_usernames: true$}
        ) }
        it {should contain_file('gitlab-shell-config').with_content(
          %r{^log_file: "/path/to/log/file.log"$}
        ) }
        it {should contain_file('gitlab-shell-config').without_content(
          %r{^  self_signed_cert: true$}
        ) }
        it {should contain_file('gitlab-shell-config').without_content(
          %r{^audit_usernames: false$}
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
    it do
      expect {
        should contain_class('gitlab::params')
      }.to raise_error(Puppet::Error, /The GitLab Puppet module does not support RedHat family of operating systems/)
    end
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
    it do
      expect {
        should contain_class('gitlab::params')
      }.to raise_error(Puppet::Error, /The GitLab Puppet module does not support Unknown family of operating systems/)
    end
  end
end
