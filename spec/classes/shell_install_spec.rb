require 'spec_helper'
describe 'gitlab::shell::install', :type => :class do
  context 'on a Debian OS' do
    let :facts do
      {
        :osfamily       => 'Debian',
        :concat_basedir => '/dne',
        :fqdn           => 'test.example.org',
      }
    end
    describe 'with default gitlab (disable shell install so test can redeclare)' do
      let :pre_condition do
        "class {'gitlab': install_gl_shell => false }"
      end
      describe 'with no parameters' do
        it { should contain_class('gitlab::params') }
        it { should contain_vcsrepo('gitlab-shell').with(
          'ensure'    => 'present',
          'path'      => '/home/git/gitlab-shell',
          'provider'  => 'git',
          'user'      => 'git',
          'source'    => 'https://gitlab.com/gitlab-org/gitlab-shell.git',
          'revision'  => 'v1.8.0',
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
