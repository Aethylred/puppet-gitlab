class{'git': }

# required to meet dependencies for bundling the gems
package{'libicu-dev':
  ensure => 'present',
}

package{'cmake':
  ensure => 'present',
}

class{'apache':
  default_vhost     => false,
  server_signature  => 'off',
  log_formats       => { common_forwarded => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b'},
}
include apache::mod::passenger
include apache::mod::shib
include redis

class{'ruby':
  version             => '2.0.0',
  set_system_default  => true,
}
class{'ruby::dev':
  bundler_package   => 'bundler',
  bundler_provider  => 'gem',
}

include postgresql::server
include postgresql::lib::devel

include shibboleth

# Set up the Shibboleth Single Sign On (sso) module
shibboleth::sso{'federation_directory':
  discoveryURL  => 'https://example.federation.org/ds/DS',
}

shibboleth::metadata{'federation_metadata':
  provider_uri  => 'https://example.federation.org/metadata/fed-metadata-signed.xml',
  cert_uri      => 'http://example.federation.org/metadata/fed-metadata-cert.pem',
}

shibboleth::attribute_map{'federation_attribute_map':
  attribute_map_uri => 'https://example.federation.org/download/attribute-map.xml',
}

include shibboleth::backend_cert


# Upload some SSL certificates and keys here.

# Setting the gitlab_url used by gitlab shell to use localhost
# because the FQDN of a test VM is unlikly to be real.
class{'gitlab':
  gitlab_url      => 'http://localhost/',
  enable_https    => true,
  redirect_http   => true,
  gitlab_app_rev  => 'master',
  shibboleth      => true,
  require         => [
    Class[
      'git',
      'postgresql::lib::devel'
    ],
    Package[
      'libicu-dev',
      'cmake'
    ]
  ]
}
