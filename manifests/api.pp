# == Class: nova::api
#
# Setup and configure the Nova API endpoint
#
# === Parameters
#
# [*admin_password*]
#   (required) The password to set for the nova admin user in keystone
#
# [*enabled*]
#   (optional) Whether the nova api service will be run
#   Defaults to false
#
# [*ensure_package*]
#   (optional) Whether the nova api package will be installed
#   Defaults to 'present'
#
# [*auth_strategy*]
#   (DEPRECATED) Does nothing and will be removed in Icehouse
#   Defaults to false
#
# [*auth_host*]
#   (optional) The IP of the server running keystone
#   Defaults to '127.0.0.1'
#
# [*auth_port*]
#   (optional) The port to use when authenticating against Keystone
#   Defaults to 35357
#
# [*auth_protocol*]
#   (optional) The protocol to use when authenticating against Keystone
#   Defaults to 'http'
#
# [*auth_uri*]
#   (optional) The uri of a Keystone service to authenticate against
#   Defaults to false
#
# [*auth_admin_prefix*]
#   (optional) Prefix to prepend at the beginning of the keystone path
#   Defaults to false
#
# [*admin_tenant_name*]
#   (optional) The name of the tenant to create in keystone for use by the nova services
#   Defaults to 'services'
#
# [*admin_user*]
#   (optional) The name of the user to create in keystone for use by the nova services
#   Defaults to 'nova'
#
# [*api_bind_address*]
#   (optional) IP address for nova-api server to listen
#   Defaults to '0.0.0.0'
#
# [*metadata_listen*]
#   (optional) IP address  for metadata server to listen
#   Defaults to '0.0.0.0'
#
# [*enabled_apis*]
#   (optional) A comma separated list of apis to enable
#   Defaults to 'ec2,osapi_compute,metadata'
#
# [*volume_api_class*]
#   (optional) The name of the class that nova will use to access volumes. Cinder is the only option.
#   Defaults to 'nova.volume.cinder.API'
#
# [*use_forwarded_for*]
#   (optional) Treat X-Forwarded-For as the canonical remote address. Only
#   enable this if you have a sanitizing proxy.
#   Defaults to false
#
# [*workers*]
#   (optional) Number of workers for OpenStack API service
#   Defaults to $::processorcount
#
# [*sync_db*]
#   (optional) Run nova-manage db sync on api nodes after installing the package.
#   Defaults to true
#
# [*neutron_metadata_proxy_shared_secret*]
#   (optional) Shared secret to validate proxies Neutron metadata requests
#   Defaults to undef
#
# [*ratelimits*]
#   (optional) A string that is a semicolon-separated list of 5-tuples.
#   See http://docs.openstack.org/trunk/config-reference/content/configuring-compute-API.html
#   Example: '(POST, "*", .*, 10, MINUTE);(POST, "*/servers", ^/servers, 50, DAY);(PUT, "*", .*, 10, MINUTE)'
#   Defaults to undef
#
# [*ratelimits_factory*]
#   (optional) The rate limiting factory to use
#   Defaults to 'nova.api.openstack.compute.limits:RateLimitingMiddleware.factory'
#
class nova::api(
  $admin_password,
  $enabled           = false,
  $ensure_package    = 'present',
  $auth_strategy     = undef,
  $auth_host         = '127.0.0.1',
  $auth_port         = 35357,
  $auth_protocol     = 'http',
  $auth_uri          = false,
  $auth_admin_prefix = false,
  $admin_tenant_name = 'services',
  $admin_user        = 'nova',
  $api_bind_address  = '0.0.0.0',
  $metadata_listen   = '0.0.0.0',
  $enabled_apis      = 'ec2,osapi_compute,metadata',
  $volume_api_class  = 'nova.volume.cinder.API',
  $use_forwarded_for = false,
  $workers           = $::processorcount,
  $sync_db           = true,
  $neutron_metadata_proxy_shared_secret = undef,
  $port_to_apache = false,
  $osapi_compute_listen_port	= undef,
  $ec2_listen_port	= undef,
  $metadata_listen_port = undef,
  $ec2_scheme	= undef,
  $keystone_ec2_url  = undef,
  $ratelimits        = undef,
  $ratelimits_factory =
    'nova.api.openstack.compute.limits:RateLimitingMiddleware.factory'
) {

  include nova::params
  require keystone::python
  include cinder::client

  Package<| title == 'nova-api' |> -> Nova_paste_api_ini<| |>

  Package<| title == 'nova-common' |> -> Class['nova::api']

  Nova_paste_api_ini<| |> ~> Exec['post-nova_config']
#FIXME: workround for ssl 
  if $port_to_apache {
     Nova_paste_api_ini<| |> ~> Service['httpd']
     Exec['post-nova_config'] ~> Service['httpd']
  } else {
     Nova_paste_api_ini<| |> ~> Service['nova-api']
  }

  if $auth_strategy {
    warning('Parameter auth_strategy is not used in class nova::api and going to be deprecated.')
  }
 
  if $osapi_compute_listen_port {
    nova_config {
	'DEFAULT/osapi_compute_listen_port': value => $osapi_compute_listen_port;
    }
  } 

  if $ec2_listen_port {
    nova_config {
	'DEFAULT/ec2_listen_port': value => $ec2_listen_port;
    }
  }

  if $metadata_listen_port {
    nova_config {
	'DEFAULT/metadata_listen_port': value => $metadata_listen_port;
    }
  }



  if $ec2_scheme {
	nova_config { 'DEFAULT/ec2_scheme': value => $ec2_scheme; }
  }

  if $keystone_ec2_url {
	nova_config { 'DEFAULT/keystone_ec2_url': value => $keystone_ec2_url; }
  }
if $port_to_apache {
    $api_enabled = false 
} else {
    $api_enabled = true
}

  nova::generic_service { 'api':
    enabled        => $api_enabled,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
    subscribe      => Class['cinder::client'],
  }
  nova_config {
    'DEFAULT/enabled_apis':          value => $enabled_apis;
    'DEFAULT/volume_api_class':      value => $volume_api_class;
    'DEFAULT/ec2_listen':            value => $api_bind_address;
    'DEFAULT/osapi_compute_listen':  value => $api_bind_address;
    'DEFAULT/metadata_listen':       value => $metadata_listen;
    'DEFAULT/osapi_volume_listen':   value => $api_bind_address;
    'DEFAULT/osapi_compute_workers': value => $workers;
    'DEFAULT/use_forwarded_for':     value => $use_forwarded_for;
  }

  if ($neutron_metadata_proxy_shared_secret){
    nova_config {
      'DEFAULT/service_neutron_metadata_proxy': value => true;
      'DEFAULT/neutron_metadata_proxy_shared_secret':
        value => $neutron_metadata_proxy_shared_secret;
    }
  } else {
    nova_config {
      'DEFAULT/service_neutron_metadata_proxy':       value  => false;
      'DEFAULT/neutron_metadata_proxy_shared_secret': ensure => absent;
    }
  }

  if $auth_uri {
    nova_config { 'keystone_authtoken/auth_uri': value => $auth_uri; }
  } else {
    nova_config { 'keystone_authtoken/auth_uri': value => "${auth_protocol}://${auth_host}:5000/"; }
  }

  nova_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $admin_tenant_name;
    'keystone_authtoken/admin_user':        value => $admin_user;
    'keystone_authtoken/admin_password':    value => $admin_password, secret => true;
  }

  if $auth_admin_prefix {
    validate_re($auth_admin_prefix, '^(/.+[^/])?$')
    nova_config {
      'keystone_authtoken/auth_admin_prefix': value => $auth_admin_prefix;
    }
  } else {
    nova_config {
      'keystone_authtoken/auth_admin_prefix': ensure => absent;
    }
  }

  if 'occiapi' in $enabled_apis {
    if !defined(Package['python-pip']) {
      package { 'python-pip':
        ensure => latest,
      }
    }
    if !defined(Package['pyssf']) {
      package { 'pyssf':
        ensure   => latest,
        provider => pip,
        require  => Package['python-pip']
      }
    }
    package { 'openstackocci':
      ensure   => latest,
      provider => 'pip',
      require  => Package['python-pip'],
    }
  }

  if ($ratelimits != undef) {
    nova_paste_api_ini {
      'filter:ratelimit/paste.filter_factory': value => $ratelimits_factory;
      'filter:ratelimit/limits':               value => $ratelimits;
    }
  }

  # Added arg and if statement prevents this from being run
  # where db is not active i.e. the compute
  if $sync_db {
    Package<| title == 'nova-api' |> -> Exec['nova-db-sync']
    exec { 'nova-db-sync':
      command     => '/usr/bin/nova-manage db sync',
      refreshonly => true,
      subscribe   => Exec['post-nova_config'],
    }
  }

  # Remove auth configuration from api-paste.ini
  nova_paste_api_ini {
    'filter:authtoken/auth_uri':          ensure => absent;
    'filter:authtoken/auth_host':         ensure => absent;
    'filter:authtoken/auth_port':         ensure => absent;
    'filter:authtoken/auth_protocol':     ensure => absent;
    'filter:authtoken/admin_tenant_name': ensure => absent;
    'filter:authtoken/admin_user':        ensure => absent;
    'filter:authtoken/admin_password':    ensure => absent;
    'filter:authtoken/auth_admin_prefix': ensure => absent;
  }

}
