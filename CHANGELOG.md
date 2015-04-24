# Releases

##0.5.7
- Update metadata as the Puppetlabs Apache module version 1.4.0 is not compatible.
- Try to reduce runtime by ignoring some directories under recursive management

##0.5.6
- Minimum changes for Gitlab 7.7 and Gitlab Shell 2.4
- Document upgrade process

##0.5.5
- Fix shib_request_settings (it's plural)

##0.5.4
- Update hook path to allow paths and not just a file

##0.5.3
- Now tries to create new repos from the git user's home directory

##0.5.2
- Set core.autocrlf git config for the gitlab user

##0.5.1
- Set time zone in gitlab.yml

##0.5.0
- Set Time Zone
- New resources:
  - gitlab::shell::repo to define repositories
  - gitlab::shell::repo::hook to define hook scripts
- Create satellite directory
- Some permissions tuning
- Fix I18 localisation warnings

##0.4.0
- Shibboleth OmniAuth.

##0.3.0
- OmniAuth added for the following providers:
  - Google
  - GitHub
  - Twitter

##0.2.0
- HTTPS works
- can redirect HTTP to HTTPS

##0.1.1
- Fix icons not displaying when _not_ using a relative URL root directory. See #1

##0.1.0 Initial release
- Initial release
- Installs GitLab on Apache with Passenger using the Puppetlabs modules
- separation of concerns: requires, but does not install dependencies.
