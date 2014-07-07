require 'spec_helper'
describe 'gitlab::db::postgresql', :type => :class do
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
      it { should contain_postgresql__server__role('git').with(
        'username'      => 'git',
        'password_hash' => 'md5f2f2886b0ee1037bb6d1c40fca97db70'
      ) }
      it { should contain_postgresql__server__database('gitlab').with(
        'dbname'    => 'gitlab',
        'owner'     => 'git'
      ) }
      it { should contain_postgresql__server__database_grant('gitlab_db_grant').with(
        'db'        => 'gitlab',
        'role'      => 'git',
        'privilege' => 'ALL'
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
