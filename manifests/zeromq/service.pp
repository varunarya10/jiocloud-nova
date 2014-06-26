#
class nova::zeromq::service inherits zeromq {

    service { 'nova-rpc-zmq-receiver':
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }

}
