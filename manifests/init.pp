# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver
class puppetserver(
  String $package_ensure,
  Boolean $package_manage,
  Array[String] $package_name,
) {
  # Ensure class declares subordinate classes
  contain puppetserver::install
  contain puppetserver::config

  # Execute classes in order
  Class['::puppetserver::install']
  -> Class['::puppetserver::config']
}
