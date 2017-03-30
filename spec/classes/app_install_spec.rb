require 'spec_helper'
describe 'gitlab::install', :type => :class do
  on_supported_os.each do |os, facts|
    # if os != 'ubuntu-14.04-x86_64' then next end
    context "on #{os}" do
      let(:facts) do
        facts.merge({
            :fqdn                   => 'test.example.org',
          })
      end
      describe 'with default gitlab' do
        let :pre_condition do
          "include gitlab\ninclude redis\ninclude apache\ninclude postgresql::server"
        end
        describe 'with no parameters' do
          it { should contain_class('gitlab::params') }
          it { should contain_vcsrepo('gitlab_app').with(
            'ensure'    => 'present',
            'path'      => '/home/git/gitlab',
            'provider'  => 'git',
            'user'      => 'git',
            'source'    => 'https://github.com/gitlabhq/gitlabhq.git',
            'revision'  => '7-14-stable',
            'require'   => 'User[gitlab]'
          ) }
          it { should contain_file('gitlab_app_dir').with(
            'ensure'  => 'directory',
            'path'    => '/home/git/gitlab',
            'owner'   => 'git',
            'ignore'  => ['.git','vendor'],
            'recurse' => true,
            'require' => 'Vcsrepo[gitlab_app]'
          ) }
        end
      end
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
    it { should raise_error(Puppet::Error, /The GitLab Puppet module does not support Unknown family of operating systems/)}
  end
end
