class nova::zeromq  {
class { '::nova::zeromq::install': } ->
class { '::nova::zeromq::config': }  ->
class { '::nova::zeromq::service': }

}
