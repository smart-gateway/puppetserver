# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver::service
class puppetserver::service {

  # Ensure the puppet server service is correctly set
  $service_state = $::puppetserver::package_ensure ? {
    'installed' => 'running',
    'present'   => 'running',
    default     => 'stopped',
  }
  service { 'puppetserver':
    ensure => $service_state,
  }
}
