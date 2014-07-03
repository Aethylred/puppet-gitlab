# This file is part of the gitlab Puppet module.
#
#     The gitlab Puppet module is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     The gitlab Puppet module is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with the gitlab Puppet module.  If not, see <http://www.gnu.org/licenses/>.
include apt
apt::ppa{'ppa:git-core/ppa':}
apt::ppa{'ppa:brightbox/ruby-ng-experimental':}
class{'git':
  require => Apt::Ppa['ppa:git-core/ppa'],
}
include apache
include apache::mod::passenger

class{'python':
  version => 2.7,
}

class{'ruby':
  version => '2.0',
  switch  => true,
  require => Apt::Ppa['ppa:brightbox/ruby-ng-experimental']
}

class{'gitlab':
  require  => [Class['ruby','python','git']]
}
