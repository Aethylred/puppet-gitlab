require 'spec_helper'
describe 'gitlab::shell::repo', :type => :define do
  context 'on a Debian OS' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :fqdn                   => 'test.example.org',
      }
    end
    describe 'with default gitlab' do
      let :pre_condition do
        "include gitlab\ninclude redis\ninclude apache"
      end
      describe 'with minimum parameters' do
        let :title do
          'test'
        end
        let :params do
          {
            :group   => 'test_group',
            :project => 'a_project'
          }
        end
        it { should contain_exec('create_gitlab_shell_repo_test').with(
          'command'     => '/home/git/gitlab-shell/bin/gitlab-projects add-project test_group/a_project.git',
          'user'        => 'git',
          'creates'     => '/home/git/repositories/test_group/a_project.git',
          'environment' => ['RAILS_ENV=production'],
          'notify'      => 'Ruby::Rake[gitlab_import_repos]',
          'path'        => ['/bin','/usr/bin']
        ) }
        it { should contain_file('test_group/a_project.git_dir').with(
          'ensure'  => 'directory',
          'path'    => '/home/git/repositories/test_group/a_project.git',
          'owner'   => 'git',
          'group'   => 'git',
          'recurse' => true,
          'require' => 'Exec[create_gitlab_shell_repo_test]'
        ) }
        it { should contain_file('test_group/a_project.git_custom_hooks_dir').with(
          'ensure'  => 'directory',
          'path'    => '/home/git/repositories/test_group/a_project.git/custom_hooks',
          'owner'   => 'git',
          'group'   => 'git',
          'recurse' => true,
          'require' => 'Exec[create_gitlab_shell_repo_test]'
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
