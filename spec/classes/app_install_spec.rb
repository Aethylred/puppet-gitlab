require 'spec_helper'
describe 'gitlab::install', :type => :class do
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
        "include gitlab\ninclude redis\ninclude apache"
      end
      describe 'with no parameters' do
        it { should contain_class('gitlab::params') }
        it { should contain_vcsrepo('gitlab_app').with(
          'ensure'    => 'present',
          'path'      => '/home/git/gitlab',
          'provider'  => 'git',
          'user'      => 'git',
          'source'    => 'https://gitlab.com/gitlab-org/gitlab-ce.git',
          'revision'  => '7-1-stable',
          'require'   => 'User[gitlab]'
        ) }
        it { should contain_file('gitlab_app_dir').with(
          'ensure'  => 'directory',
          'path'    => '/home/git/gitlab',
          'owner'   => 'git',
          'recurse' => true,
          'require' => 'Vcsrepo[gitlab_app]'
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
