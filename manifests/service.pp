# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver::service
class puppetserver::service {

  # Ensure the puppet server service is correctly set
  service { 'puppetserver':
    ensure => $::puppetserver::package_ensure,
  }
}
