# GitLab Puppet Module

[![Build Status](https://travis-ci.org/Aethylred/puppet-gitlab.svg?branch=master)](https://travis-ci.org/Aethylred/puppet-gitlab)

This Puppet module installs, manages and configures the [GitLab](http://gitlab.org/) open source code repository. This module configures GitLab to run on [Apache](http://httpd.apache.org/) and [Passenger](https://www.phusionpassenger.com/) using the [Puppetlabs Apache Module](https://github.com/puppetlabs/puppetlabs-apache). Apache is used instead of [Ngnix](http://nginx.org/) as there are some authorisation models that have already been solved for Apache and not yet resolved for Ngnix.

# Supported Distributions

As GitLab requires Ruby 2.0.0 this module has been developed to work on Ubuntu 14.04LTS which uses this as it's natural Ruby version. Work has been done to try and make it work with Ubuntu 12.04LTS, but runs into issues getting the gems installed correctly.

# Supported Gitlab Versions

This module has been used on:

* Gitlab 6.5 Stable
* Gitlab 7.5 Stable
* Gitlab 7.7 Stable

# Usage

There is a complete install [manifest example in the tests directory](tests/init.pp). An updated version for [Gitlab 7.7 is also provided](tests/init-7.7.pp).

# Upgrading Gitlab

The upgrade process is a WORK IN PROGRESS! Don't do it.

...the puppet manifest creates a new database, rather than updating it, which drops everything. (also, yay for test servers that caught this before going into production)

1. Before upgrading stop Gitlab.

    ```
    $ service apache2 stop
    $ service gitlab stop
    ```

1. Back up Gitlab:

    ```
    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
    ```

1. On the puppetmaster edit the Puppet Manifest for gitlab, and include new version references and update package dependencies if required:

    ```puppet
    class{'gitlab':
      gitlab_url  => 'http://localhost/',
      gitlab_app_rev    => '7-7-stable',
      gitlab_shell_rev  => 'v2.4.1',
      require     => [
        Class[
          'git',
          'postgresql::lib::devel'
        ],
        Package[
          'libicu-dev',
          'cmake',
          'libkrb5-dev'
        ]
      ]
    }
    ```

1. No don't do that.

1. Migrate database:

    ```
    sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
    ```

1. Clean up assets and cache:

    ```
    sudo -u git -H bundle exec rake assets:clean assets:precompile cache:clear RAILS_ENV=production
    ```

1. Use puppet to restart services and check everything:

    ```
    puppet agent -t
    ```

# Dependencies

* [**puppetlabs/stdlib**](https://forge.puppetlabs.com/puppetlabs/stdlib)
* [**puppetlabs/apache**](https://forge.puppetlabs.com/puppetlabs/apache)
* [**puppetlabs/vcsrepo**](https://forge.puppetlabs.com/puppetlabs/vcsrepo)
* [**puppetlabs/postgresql**](https://forge.puppetlabs.com/puppetlabs/postgresql)
* [**Aethylred/git**](https://forge.puppetlabs.com/Aethylred/git)
* [**thomasvandoren/redis**](https://forge.puppetlabs.com/thomasvandoren/redis)
* [**puppetlabs/ruby**](https://github.com/puppetlabs/puppetlabs-ruby) this module relies on a patches that are currently only in the master branch of the GitHub repository and not the version published at the Puppet Forge.
* [**Aethylred/shibboleth**](https://github.com/Aethylred/puppet-shibboleth) this module is only required if the Shibboleth authentication is being used.

## Packages

The following packages are required to get GitLab installed. They're not installed directly by this module in case this interferes with them being managed or required by other modules.

* `cmake`
* `libicu-dev`

For Gitlab 7.7 and later the Kerberos development libraries are also required:

* `libkrb5-dev`

# Classes

This module provides a base `gitlab` class that will be used in most manifests. There are a number of private classes set up to reduce the complexity of the base class, however some may be of use in separating some of the functionality across different hosts, e.g. running the database on a separate host.

## Public Classes

### gitlab

* *gitlab_url* Sets the URL to the GitLab application. Defaults to http://localhost/
* *relative_url_root* Sets the relative root URL of the GitLab application. The default is `/`
* *port* Sets the port that the GitLab application runs on. The default is `80`
* *enable_https* If set to true, the GitLab application will use HTTPS. This is required to be true if `omniauth` or `shibboleth` are used.
* *redirect_http* If set to true, Apache will be configured to redirect port 80 to port 443.
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
* *ssl_cert* sets the path to the Apache web server SSL certificate. The default is undefined.
* *ssl_key* sets the path to the Apache web server SSL public key. The default is undefined.
* *ssl_ca* sets the path to the Apache web server SSL CA certificate. The default is undefined.
* *omniauth* Hashes passed to this parameter will be used to configure OmniAuth. See the [section on configuring OmniAuth](#Using the OmniAuth parameter). The default is undefined, which disables OmniAuth.
* *allow_sso* If set to true, this will allow GitLab to create users from SSO/OmniAuth logins. The default is false.
* *block_auto_create* If set to true, users created by SSO/OmniAuth logins will need to be approved by an administrator before they can do anything. The default is true.
* *shibboleth* If sets to true this configures GitLab to use the Shibboleth OmniAuth provider. See the section on [Shibboleth](#Shibboleth) for details.
* *signup_enabled* If set to `true` this will allow users to create new accounts via the login screen, otherwise all accounts must be created by the site Administrators. The default is `false`.
* *signin_enabled* If set to `false` this will require users to use one of the OmniAuth providers instead of being able to log in with a username and password. The default is `true`. **NOTE**: this needs to be `true` to log in with the default administrator account and do the initial set up of the Gitlab application and to appoint new administrators.
* *time_zone* This sets the time zone that the Gitlab application runs in, dates and time will be displayed relative to this time zone. Run "rake -D time" for a list of tasks for finding time zone names. The default is undefined, which will use the UTC.

#### Using the OmniAuth parameter

The `omniauth` parameter on the base `gitlab` class takes an array of hashes that define an OmniAuth provider. Check the [test scripts](tests/init-omni-all.pp) for examples. More information on [GitLab OmniAuth Providers](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/integration/omniauth.md).

Currently the list of supported providers is:
- Google (`google`, `google+` or `google_oauth2`)
- GitHub (`github`)
- Twitter (`twitter`)
- Shibboleth (no provider, has it's own parameter)

**NOTE:** if the `allow_sso` is true and `block_auto_create` is false, then anyone with an identity on any of the configured OmniAuth providers can log in and use the GitLab instance, which includes access to internal projects.

#### Shibboleth

Setting the `shibboleth` parameter will enable the [Shibboleth](http://shibboleth.net/) OmniAuth provider for GitLab. However this is not straight forward and additional dependencies and work are required for this to work correctly. Although this is a separate parameter, it is compatible with the other OmniAuth providers.

* The [Puppetlabs Apache Module](https://github.com/puppetlabs/puppetlabs-apache) will need to be a version that manages `mod_shib` correctly. Currently this is the master branch from the git repository, not the current version from the Puppet Forge.
* The Shibboleth SP configuration in `/etc/shibboleth/shibboleth2.xml` will need to be correct. There is a companion module for the Puppetlabs Apache module [on GitHub](https://github.com/Aethylred/puppet-shibboleth)
* The GitLab site's back-end x509 certificate will need to be registered with the Shibboleth IDp or Shibboleth Federation to be recognised as a valid service. This is a manual task as it is very dependent on the work flows provided by those services.

### gitlab::db::postgresql

This class sets up a PostgreSQL database for the GitLab application. It does not install the PostgreSQL  service, this should be declared beforehand.

* *gitlab_server* used to grant the host running the GitLab application access to the database. The default is undefined, which does not create any access rights.
* *db_user* sets the database user for the Gitlab application database. The default is `git`
* *db_name* sets the database name for the GitLab application database. The default is `gitlab`
* *db_host* sets the database host, the default is undefined which uses the localhost.
* *db_user_password*  sets the password used by the database user to access the GitLab application database. The default is `veryveryunsafe`
* *db_user_passwd_hash* if this is set, this hash is used as the password for the database user to access the GitLab application database. The default is undefined, which reverts to using the password set by *db_user_password*

## Private Classes

### gitlab::params

Contains the global variables and defaults for the module. Should not be used directly.

This class has no parameters.

### gitlab::install

Runs the install procedure using `vcsrepo` to use git to install GitLab from the [GitLab Community Edition Repository](https://gitlab.com/gitlab-org/gitlab-ce). This separation simplifies adding different installers in later versions.

* *app_dir* this sets the location to install the GitLab application. The default is `/home/git/gitlab`.
* *repository* this sets the repository from which the GitLab application is installed. The default is https://gitlab.com/gitlab-org/gitlab-ce.git
* *revision* this sets the git revision (branch, tag, or hash) to be cloned. The default is `7-3-stable`
* *user* this sets the user who should clone the GitLab application. The default is `git`

### gitlab::shell::install

Runs the install procedure to install the GitLab command line shell, allowing it to potentially be installed independently of the GitLab application. (this use case is not yet tested)

* *gitlab_url* this sets the base URL for the GitLab application.
* *user* this sets the user who should clone the GitLab shell repository. The default is `git`
* *user_home* this sets the user's home directory. The default is `/home/git`
* *repository* this sets the repository from which the GitLab shell is installed. The default is https://gitlab.com/gitlab-org/gitlab-shell.git
* *revision* this sets the git revision (branch, tag, or hash) to be cloned. The default is `v2.0.0`
* *repository_dir* this sets the directory where the GitLab repositories are stored. The default is `/home/git/repositories`
* *auth_file* this sets the path to a file that lists the authorised keys allowed to access the git repositories.
* *selfsigned_certs* if set to true, self-signed certificates will be generated and used.
* *audit_usernames* if set to true, the GitLab shell will audit usernames.
* *log_level* this sets the logging level of the GitLab shell. The default is `INFO`
* *gl_shell_logfile* this sets the path to the GitLab shell log file.

## Defined Resources

### gitlab::shell::repo

This resources uses the Gitlab shell to create a repository and import it into the Gitlab application. If the repository's group or user does not exist, a new group will be created to host the repository. If the repository already exist, Puppet remains idempotent and does nothing but acknowledge it's existence. Ownership of the repository is assigned to the first administrator, which will usually be the default administrator. Any administrator should be able to reassign ownership of the repository or move it into another namespace. This resource is a bit clumsy, and not the best way to create repositories, but it does make Puppet aware that a repository exist regardless of whether Puppet created it a not and was a prerequisite for managing repository hook scripts.

#### Parameters

* *group*: This is the group or user under which the repository will be created. If no group or user exists in the Gitlab instance with this name a group will be created with the first administrator as the owner. This is a required parameter with no default value.
* *project*: This is the name of the repository to be created under the group defined by the `group` parameter. The owner will be the first administrator. This is a required parameter with no default value.

### gitlab::shell::repo::hook

This resource creates a [Git server-side hook script](http://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#Server-Side-Hooks) that will be executed at different stages through pushing a git commit to the target repository. Creation of hooks requires that the repository be previously defined in the Puppet manifest. These hooks are not currently visible in the Gitlab web application. These hook scripts should follow the [Gitlab custom hook guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/hooks/custom_hooks.md).

The repository must be declared as a resource with `gitlab::shell::repo`.

**NOTE:** This resource requires [Gitlab shell v2.2.0 or later](https://gitlab.com/gitlab-org/gitlab-shell/tree/v2.2.0) which has the custom hook scripts feature.

There are examples of how these scripts should be declared in the [test scripts](tests/with_custom_hooks.pp)

One of, but not both, `content` or `source` is required. If both, or none of, the `content` or `source` parameters are defined an error will be thrown.

#### Parameters

* *target*: This is the name of the target repository as defined when declared with `gitlab::shell::repo`. This parameter is required and has no default value.
* *path*: this is an the name of the hook script file, this is set to the `name` of the resource by default. Git only executes scripts with the name `pre-recieve`, `update`, or `post-recieve`, scripts with other names or paths will need to be explicitly called by a recognised script.
* *content*: The content of the hook script will be set to the value passed via this parameter, similar to the standard Puppet `file` resource. One of, but not both, `content` or `source` is required. The default is undefined.
* *source*: The hook script will be copied from this location similar to the standard Puppet `file` resource. One of, but not both, `content` or `source` is required. The default is undefined.

# Issues

When running the `gitlab:check` rake command to verify the Gitlab installation, it should all be correct with the exception of the init script check. This is correct behaviour as this module deploys it's own init script customised to work with Apache, so has all the Unicorn parts removed.

Hence, the following output is expected and no corrective action should be taken.
```
Init script up-to-date? ... no
  Try fixing it:
  Redownload the init script
  For more information see:
  doc/install/installation.md in section "Install Init Script"
  Please fix the error above and rerun the checks.
```

# To Do

* Figure out icons for custom OmniAuth providers ([check ticket](http://feedback.gitlab.com/forums/176466-general/suggestions/5228989-allow-icons-for-custom-omniauth-providers))

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

## Using OmniAuth and Shibboleth
* https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/integration/omniauth.md
* https://groups.google.com/forum/#!msg/gitlabhq/BAhpzoW9KQ8/R62OvUL04KQJ
* https://github.com/toyokazu/omniauth-shibboleth
* https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/integration/shibboleth.md


# Attribution

## puppet-blank

This module is derived from the [puppet-blank](https://github.com/Aethylred/puppet-blank) module by Aaron Hicks (aethylred@gmail.com)

This module has been developed for the use with Open Source Puppet (Apache 2.0 license) for automating server & service deployment.

* http://puppetlabs.com/puppet/puppet-open-source/

# Gnu General Public License

[![GPL3](http://www.gnu.org/graphics/gplv3-127x51.png)](http://www.gnu.org/licenses)

This file is part of the gitlab Puppet module.

The gitlab Puppet module is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The gitlab Puppet module is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with the gitlab Puppet module.  If not, see <http://www.gnu.org/licenses/>.
