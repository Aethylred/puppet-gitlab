# GitLab Puppet Module

[![Build Status](https://travis-ci.org/Aethylred/puppet-gitlab.svg?branch=master)](https://travis-ci.org/Aethylred/puppet-gitlab)

This Puppet module installs, manages and configures the [GitLab](http://gitlab.org/) open source code repository. This module configures GitLab to run on [Apache](http://httpd.apache.org/) and [Passenger](https://www.phusionpassenger.com/) using the [Puppetlabs Apache Module](https://github.com/puppetlabs/puppetlabs-apache). Apache is used instead of [Ngnix](http://nginx.org/) as there are some authorisation models that have already been solved for Apache and not yet resolved for Ngnix.

# Supported Distributions

As GitLab requires Ruby 2.0.0 this module has been developed to work on Ubuntu 14.04LTS which uses this as it's natural Ruby version. Work has been done to try and make it work with Ubuntu 12.04LTS, but runs into issues getting the gems installed correctly.

# Usage

There is a complete install [manifest example in the tests directory](tests/init.pp).

# Dependencies

* [**puppetlabs/stdlib**](https://forge.puppetlabs.com/puppetlabs/stdlib)
* [**puppetlabs/apache**](https://forge.puppetlabs.com/puppetlabs/apache)
* [**puppetlabs/vcsrepo**](https://forge.puppetlabs.com/puppetlabs/vcsrepo)
* [**puppetlabs/postgresql**](https://forge.puppetlabs.com/puppetlabs/postgresql)
* [**Aethylred/git**](https://forge.puppetlabs.com/Aethylred/git)
* [**thomasvandoren/redis**](https://forge.puppetlabs.com/thomasvandoren/redis)
* **puppetlabs/ruby** this module relies on a [patched version of the PuppetLabs ruby module](https://github.com/Aethylred/puppetlabs-ruby/tree/all_features) that includes the `ruby::bundle` and `ruby::rake` resources. Check the supplied [Puppetfile](Puppetfile) that can be used by [librarian-puppet](https://github.com/rodjek/librarian-puppet) to install the modules.

# Classes

This module provides a base `gitlab` class that will be used in most manifests. There are a number of private classes set up to reduce the complexity of the base class, however some may be of use in separating some of the functionality across different hosts, e.g. running the database on a separate host.

## Public Classes

### gitlab

* *gitlab_url* Sets the URL to the GitLab application. Defaults to http://localhost/
* *relative_url_root* Sets the relative root URL of the GitLab application. The default is `/`
* *port* Sets the port that the GitLab application runs on. The default is `80`
* *enable_https* If set to true, the GitLab application will use HTTPS. The default is `false`. Not yet implemented!
* *email_address* sets the default administrator email address
* *user* sets the user that hosts the GitLab application and repositories. The default is `git`
* *user_home* sets the home directory for the *user* and holds the GitLab application and repositories. The default is `/home/git`
* *install_gl_shell* If set to `true` the GitLab shell will be installed. The default is `true`
* *gitlab_shell_repo* this sets the repository from which the GitLab shell is installed. The default is https://gitlab.com/gitlab-org/gitlab-shell.git
* *gitlab_shell_rev* this sets the git revision (branch, tag, or hash) to be cloned. The default is `v1.9.6`
* *manage_db* if this is set to true, the GitLab application database will be set up on this node. The default is true.
* *db_user* sets the database user for the Gitlab application database. The default is `git`
* *db_name* sets the database name for the GitLab application database. The default is `gitlab`
* *db_host* sets the database host, the default is undefined which uses the localhost.
* *db_port* sets the port to access the database. The default is undefined which uses the default port.
* *db_user_password*  sets the password used by the database user to access the GitLab application database. The default is `veryveryunsafe`
* *db_user_passwd_hash* if this is set, this hash is used as the password for the database user to access the GitLab application database. The default is undefined, which reverts to using the password set by *db_user_password*
* *servername* This sets the server name in the Apache configuration. Defautls to the fully qualified domain name of the host.
* *selfsigned_certs* If set to `true` self-signed certificates are used. The default is `true`
* *audit_usernames* If set to `true`, user names will be audited in the GitLab shell. The default is true.
* *log_level* sets the default logging level of the GitLab shell. The default is `INFO`.
* *gl_shell_logfile* sets the path to the GitLab shell logging file. The default is undefined.
* *gitlab_app_dir* sets the directory where the gitlab application will be installed. The default is `/home/git/gitlab`
* *gitlab_app_repo* this sets the repository from which the GitLab application is installed. The default is https://gitlab.com/gitlab-org/gitlab-ce.git
* *gitlab_app_rev* this sets the git revision (branch, tag, or hash) to be cloned. The default is `7-1-stable`
* *default_project_limit* sets the default maximum number of projects for users. The default is 10.
* *allow_group_creation* if set to true, this will allow users to create new groups on demand. The default is `true`
* *allow_name_change* if set to true, this will allow users to change their name and namespace of all their projects. The default is `true`.
* *default_theme_id * this sets the default style and theme of the GitLab application.  The default is to use theme `2`, which is 'Mars'
* *project_issues* if set to true, projects will be able to use the issue tracker. The default is `true`.
* *project_merge_requests* if set to true, projects will be able to accept merge requests from repository forks. The default is `true`.
* *project_wiki* if set to true, projects will be able to use the internal wiki. The default is `true`.
* *project_snippets* if set to true, projects will be able to share code snippets. The default is `true`.
* *project_visibility* this sets the default project sharing policy. The default is to make new projects `private`.
* *enable_gravatar* if this is set to true, [Gravatar](https://en.gravatar.com/) user avatar images will be enabled. The default is `true`.
* *ssh_port* sets the default SSH port that GitLab listens on. The default is 22.

### gitlab::db::postgresql

This class sets up a postgres database for the GitLab application. It does not install postgresql, this should be declared beforehand.

* *db_name*
* *db_user*
* *db_user_password*
* *db_user_passwd_hash*
* *gitlab_server*
* *db_host*

## Private Classes

### gitlab::params

Contains the global variables and defaults for the module. Should not be used directly.

This class has no parameters.

### gitlab::install

Runs the install procedure using `vcsrepo` to use git to install GitLab from the [GitLab Community Edition Repository](https://gitlab.com/gitlab-org/gitlab-ce). This separation simplifies adding different installers in later versions.

* *app_dir* this sets the location to install the GitLab application. The default is `/home/git/gitlab`.
* *repository* this sets the repository from which the GitLab application is installed. The default is https://gitlab.com/gitlab-org/gitlab-ce.git
* *revision* this sets the git revision (branch, tag, or hash) to be cloned. The default is `7-1-stable`
* *user* this sets the user who should clone the GitLab application. The default is `git`

### gitlab::shell::install

Runs the install procedure to install the GitLab command line shell, allowing it to potentially be installed independently of the GitLab application. (this use case is not yet tested)

* *gitlab_url* this sets the base URL for the GitLab application.
* *user* this sets the user who should clone the GitLab shell repository. The default is `git`
* *user_home* this sets the user's home directory. The default is `/home/git`
* *repository* this sets the repository from which the GitLab shell is installed. The default is https://gitlab.com/gitlab-org/gitlab-shell.git
* *revision* this sets the git revision (branch, tag, or hash) to be cloned. The default is `v1.9.6`
* *repository_dir* this sets the directory where the GitLab repositories are stored. The default is `/home/git/repositories`
* *auth_file* this sets the path to a file that lists the authorised keys allowed to access the git repositories.
* *selfsigned_certs* if set to true, self-signed certificates will be generated and used.
* *audit_usernames* if set to true, the GitLab shell will audit usernames.
* *log_level* this sets the logging level of the GitLab shell. The default is `INFO`
* *gl_shell_logfile* this sets the path to the GitLab shell log file.

# To Do

* Run the site over HTTPS
* Configure authentication (Omniauth and Shibboleth)
* Create repositories.
* Inject hook scripts into repositories.

# References

## Other GitLab puppet modules

These are good implementations, but install GitLab on Ngnix, which is not what's being done here.

* https://github.com/sbadia/puppet-gitlab
* https://github.com/spuder/puppet-gitlab
* https://github.com/lboynton/puppet-gitlab

##GitLab installation references
* https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache
* https://gitlab.com/gitlab-org/cookbook-gitlab/tree/master
* http://k-d-w.org/node/94
* https://www.digitalocean.com/community/articles/how-to-set-up-gitlab-as-your-very-own-private-github-clone
* https://shanetully.com/2012/08/23/running-gitlab-from-a-subdirectory-on-apache/
* https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md

## Using Shibboleth
* https://groups.google.com/forum/#!msg/gitlabhq/BAhpzoW9KQ8/R62OvUL04KQJ
* https://github.com/toyokazu/omniauth-shibboleth


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

[![GPL3](http://www.gnu.org/graphics/gplv3-127x51.png)](http://www.gnu.org/licenses)

This file is part of the gitlab Puppet module.

The gitlab Puppet module is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The gitlab Puppet module is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with the gitlab Puppet module.  If not, see <http://www.gnu.org/licenses/>.
