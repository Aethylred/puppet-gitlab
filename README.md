# GitLab Puppet Module

This Puppet module installs, manages and configures the [GitLab](http://gitlab.org/) open source code repository. This module configures GitLab to run on [Apache](http://httpd.apache.org/) and [Passenger](https://www.phusionpassenger.com/) using the [Puppetlabs Apache Module](https://github.com/puppetlabs/puppetlabs-apache). Apache is used instead of [Ngnix](http://nginx.org/) as there are some authorisation models that have already been solved for Apache and not yet resolved for Ngnix.

# References

## Other GitLab puppet modules

These are good implementations, but install GitLab on Ngnix, which is not what's being done here.

* https://github.com/sbadia/puppet-gitlab
* https://github.com/spuder/puppet-gitlab
* https://github.com/lboynton/puppet-gitlab

GitLab installation references
* https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache
* https://gitlab.com/gitlab-org/cookbook-gitlab/tree/master
* http://k-d-w.org/node/94
* https://www.digitalocean.com/community/articles/how-to-set-up-gitlab-as-your-very-own-private-github-clone
* https://shanetully.com/2012/08/running-gitlab-from-a-subdirectory-on-apache/
* https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md


# Attribution

## puppet-blank

This module is derived from the [puppet-blank](https://github.com/Aethylred/puppet-blank) module by Aaron Hicks (aethylred@gmail.com)

This module has been developed for the use with Open Source Puppet (Apache 2.0 license) for automating server & service deployment.

* http://puppetlabs.com/puppet/puppet-open-source/

## rspec-puppet-augeas

This module includes the [Travis](https://travis-ci.org) configuration to use [`rspec-puppet-augeas`](https://github.com/domcleal/rspec-puppet-augeas) to test and verify changes made to files using the [`augeas` resource](http://docs.puppetlabs.com/references/latest/type.html#augeas) available in Puppet. Check the `rspec-puppet-augeas` [documentation](https://github.com/domcleal/rspec-puppet-augeas/blob/master/README.md) for usage.

This will require a copy of the original input files to `spec/fixtures/augeas` using the same filesystem layout that the resource expects:

    $ tree spec/fixtures/augeas/
    spec/fixtures/augeas/
    `-- etc
        `-- ssh
            `-- sshd_config

# Gnu General Public License

[![GPL3](http://www.gnu.org/graphics/gplv3-127x51.png)]](http://www.gnu.org/licenses)

This file is part of the gitlab Puppet module.

The gitlab Puppet module is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The gitlab Puppet module is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with the gitlab Puppet module.  If not, see <http://www.gnu.org/licenses/>.
