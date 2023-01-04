# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver::install
class puppetserver::install {
  if $puppetserver::package_manage {
    case $puppetserver::package_ensure {
      'installed', 'present': {
        notify { 'Puppet Server Module Installing...': }
      }
      'purged', 'absent': {
        notify { 'Puppet Server Module Uninstalling...': }
      }
      'disabled': {
        notify { 'Puppet Server Module Disabling...': }
      }
      default: {
        notify { "Unknown 'package_ensure' value ${puppetserver::package_ensure}": }
      }
    }
  }
}
