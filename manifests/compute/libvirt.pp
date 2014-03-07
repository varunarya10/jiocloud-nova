# == Class: nova::compute::libvirt
#
# Install and manage nova-compute guests managed
# by libvirt
#
# === Parameters:
#
# [*libvirt_type*]
#   (optional) Libvirt domain type. Options are: kvm, lxc, qemu, uml, xen
#   Defaults to 'kvm'
#
# [*vncserver_listen*]
#   (optional) IP address on which instance vncservers should listen
#   Defaults to '127.0.0.1'
#
# [*migration_support*]
#   (optional) Whether to support virtual machine migration
#   Defaults to false
#
class nova::compute::libvirt (
  $libvirt_type      = 'kvm',
  $vncserver_listen  = '127.0.0.1',
  $migration_support = false,
  $libvirt_images_type = 'default',
  $libvirt_images_volume_group = 'Nova_Volumes',
  $snapshot_image_format = false,
) {

  include nova::params

  Service['libvirt'] -> Service['nova-compute']

  if($::osfamily == 'Debian') {
    package { "nova-compute-${libvirt_type}":
      ensure => present,
      before => Package['nova-compute'],
    }
  }

  if($::osfamily == 'RedHat' and $::operatingsystem != 'Fedora') {
    service { 'messagebus':
      ensure   => running,
      enable   => true,
      provider => $::nova::params::special_service_provider,
    }
    Package['libvirt'] -> Service['messagebus'] -> Service['libvirt']

  }

  if $migration_support {
    if $vncserver_listen != '0.0.0.0' {
      fail('For migration support to work, you MUST set vncserver_listen to \'0.0.0.0\'')
    } else {
      class { 'nova::migration::libvirt': }
    }
  }

if !defined(Package[$::nova::params::libvirt_package_name]) {
  package { 'libvirt':
    ensure => present,
    name   => $::nova::params::libvirt_package_name,
  }
}

if !defined(Service[$::nova::params::libvirt_service_name]) {
  service { 'libvirt' :
    ensure   => running,
    name     => $::nova::params::libvirt_service_name,
    provider => $::nova::params::special_service_provider,
    require  => Package['libvirt'],
  }
}

  if $libvirt_images_type == 'lvm' {
    nova_config {
      'DEFAULT/compute_driver':   value => 'libvirt.LibvirtDriver';
      'DEFAULT/libvirt_type':     value => $libvirt_type;
      'DEFAULT/connection_type':  value => 'libvirt';
      'DEFAULT/vncserver_listen': value => $vncserver_listen;
      'DEFAULT/libvirt_images_type': value => $libvirt_images_type;
      'DEFAULT/libvirt_images_volume_group': value => $libvirt_images_volume_group;
    }
  } else {
    nova_config {
      'DEFAULT/compute_driver':   value => 'libvirt.LibvirtDriver';
      'DEFAULT/libvirt_type':     value => $libvirt_type;
      'DEFAULT/libvirt_images_type': value => $libvirt_images_type;
      'DEFAULT/connection_type':  value => 'libvirt';
      'DEFAULT/vncserver_listen': value => $vncserver_listen;
    }
  }

  if $snapshot_image_format {
     nova_config { 'DEFAULT/snapshot_image_format': value => $snapshot_image_format; }
  }
}
