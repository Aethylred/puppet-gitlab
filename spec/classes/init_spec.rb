require 'spec_helper'
describe 'gitlab', :type => :class do
  context 'on a Debian OS' do
    let :facts do
      {
        :osfamily       => 'Debian',
        :concat_basedir => '/dne',
      }
    end
    describe 'with no parameters' do
      it { should contain_class('gitlab::params') }
      it { should contain_user('gitlab').with(
        'ensure'        => 'present',
        'name'          => 'git',
        'home'          => '/home/git',
        'comment'       => 'GitLab services and application user',
        'managehome'    => true,
        'shell'         => '/bin/bash'
      ) }
      it { should contain_class('gitlab::shell::install').with(
        'user'        => 'git',
        'user_home'   => '/home/git',
        'repository'  => 'https://gitlab.com/gitlab-org/gitlab-shell.git',
        'revision'    => 'v1.8.0'
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
