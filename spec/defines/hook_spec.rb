require 'spec_helper'
describe 'gitlab::shell::repo::hook', :type => :define do
  context 'on a Debian OS' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :fqdn                   => 'test.example.org',
      }
    end
    describe 'with default gitlab and a test repo' do
      let :pre_condition do
        "include gitlab\ninclude redis\ninclude apache\nclass gitlab::shell::repo{'test': group 
        =>'test_group', project => 'test_project'}"
      end
      describe 'when provided content' do
        let :title do
          'atest'
        end
        let :params do
          {
            :target  => 'test',
            :content => 'this is a test'
          }
          it { should contain_file('test_hook_atest').with(
            'ensure'  => 'file',
            'path'    => $hook_path,
            'owner'   => 'git',
            'group'   => 'git',
            'mode'    => '0750',
            'content' => 'this is a test',
            'require' => ['File[/home/git/repositories/test_group/test_project.git/custom_hooks]','Gitlab::Shell::Repo[test]']
          ) }
          it { should contain_file('test_hook_atest').without('source') }
        end
      end
      describe 'when provided a source' do
        let :title do
          'atest'
        end
        let :params do
          {
            :target => 'test',
            :source => '/path/to/file'
          }
          it { should contain_file('test_hook_atest').with(
            'ensure'  => 'file',
            'path'    => $hook_path,
            'owner'   => 'git',
            'group'   => 'git',
            'mode'    => '0750',
            'source'  => '/path/to/file',
            'require' => ['File[/home/git/repositories/test_group/test_project.git/custom_hooks]','Gitlab::Shell::Repo[test]']
          ) }
          it { should contain_file('test_hook_atest').without('content') }
        end
      end
      describe 'when not provided source or content' do
        let :title do
          'atest'
        end
        let :params do
          {
            :target => 'test'
          }
          it { should raise_error(Puppet::Error, /gitlab::shell::repo::hook requires a content or source parameter, but niether have been provided/) }
        end
      end
      describe 'when provided both source or content' do
        let :title do
          'atest'
        end
        let :params do
          {
            :target  => 'test',
            :source  => '/path/to/file',
            :content => 'this is a test'
          }
          it { should raise_error(Puppet::Error, /gitlab::shell::repo::hook requires only one of content or source parameter, but not both/) }
        end
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
    let :title do 'test' end
    # Nothing to test
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
    let :title do 'test' end
    # Nothing to test
  end
end
