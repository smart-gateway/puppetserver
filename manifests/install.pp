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
        Class['::puppetserver::implementation::installer']
      }
      'purged', 'absent': {
        Class['::puppetserver::implementation::uninstaller']
      }
      'disabled': {
      }
      default: {
        notify { "Unknown 'package_ensure' value ${puppetserver::package_ensure}": }
      }
    }
  }
}
