require 'spec_helper'
describe 'gitlab::db::postgresql', :type => :class do
  on_supported_os.each do |os, facts|
    if os != 'redhat-6-x86_64' and os != 'ubuntu-14.04-x86_64' then next end
    context "on #{os}" do
      let(:facts) do
        facts.merge({
            :fqdn                   => 'test.example.org',
          })
      end
      describe 'with base gitlab class (disable database management so test can redeclare)' do
        let :pre_condition do
          "class{'gitlab': manage_db => false, }\ninclude redis\ninclude apache\ninclude postgresql::server"
        end
        describe 'with no parameters' do
          it { should contain_class('gitlab::params') }
          it { should contain_postgresql__server__role('git').with(
            'username'      => 'git',
            'password_hash' => 'md5f2f2886b0ee1037bb6d1c40fca97db70'
          ) }
          it { should contain_postgresql__server__database('gitlab').with(
            'dbname'    => 'gitlab',
            'owner'     => 'git',
            'encoding'  => 'unicode'
          ) }
          it { should contain_postgresql__server__database_grant('gitlab_db_grant').with(
            'db'        => 'gitlab',
            'role'      => 'git',
            'privilege' => 'ALL'
          ) }
        end
        describe 'when given a database name' do
          let :params do
            {
              :db_name => 'notgit'
            }
          end
          it { should contain_postgresql__server__database('notgit').with_dbname('notgit') }
          it { should contain_postgresql__server__database_grant('gitlab_db_grant').with_db('notgit') }
        end
        describe 'when given a database user' do
          let :params do
            {
              :db_user => 'notgit'
            }
          end
          it { should contain_postgresql__server__role('notgit').with(
            'username'      => 'notgit',
            'password_hash' => 'md5e01b812234a936869f172a678fd212b2'
          ) }
          it { should contain_postgresql__server__database('gitlab').with_owner('notgit') }
          it { should contain_postgresql__server__database_grant('gitlab_db_grant').with_role('notgit') }
        end
        describe 'when given a password' do
          let :params do
            {
              :db_user_password => 'incleartextareyoustupid'
            }
          end
          it { should contain_postgresql__server__role('git').with(
            'password_hash' => 'md5dd921b26fd909f62430886179ecf73f2'
          ) }
        end
        describe 'when given a password hash' do
          let :params do
            {
              :db_user_passwd_hash => 'md5dd921b26fd909f62430886179ecf73f2'
            }
          end
          it { should contain_postgresql__server__role('git').with(
            'password_hash' => 'md5dd921b26fd909f62430886179ecf73f2'
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
