#
class nova::zeromq::config inherits zeromq {
### Workaround to add upstart script for nova-rpc-zmq-receiver
  file { '/etc/init/nova-rpc-zmq-receiver.conf':
	ensure  => file,
        owner   => root,
        group   => root,
        mode    => 0644,
        source => "$puppet_master_files/openstack/all/_etc_init_nova-rpc-zmq-receiver.conf",
  }    

  file { '/etc/init.d/nova-rpc-zmq-receiver':
	ensure	=> symlink,
	target	=> '/lib/init/upstart-job',
  }

  file { "/etc/matchmaker":
	ensure	=> directory,
        owner   => root,
        group   => root,
        mode    => 0644,
  }

  ->

  file { "/etc/matchmaker/matchmaker.json":
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => 0644,
        content => template("zeromq/matchmaker.json.erb"),
  }
  
### Adding group openstack and adding nova, glance, cinder to it
### Workaround to use same zmq receiver for all components 

  group { 'openstack':
    	name	=> 'openstack',
	ensure	=> present,
	gid	=> '200',
	system	=> true,
	members	=> ['nova'],
  }

}
