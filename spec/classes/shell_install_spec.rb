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
    let :pre_condition do
      'include gitlab'
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
