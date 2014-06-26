class nova::zeromq::install inherits zeromq {
#  require nova::scheduler

  $pkgs_zmq_deps = ['libzmq1','python-zmq']

## Workaround for zmq to work as currently zmq-receiver is packaged with nova-scheduler package
#  package { 'scheduler-compute':
#    ensure 	=> installed,
#    name   	=> 'nova-scheduler',
#  }

  package { $pkgs_zmq_deps:
    ensure	=> installed,
  }

}

