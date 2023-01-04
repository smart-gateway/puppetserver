# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver
class puppetserver(
  String        $package_ensure = 'installed',
  Boolean       $package_manage = true,
  String        $control_repo_url,
  String        $control_repo_key,
  String        $runner_ensure = 'installed',
  Boolean       $runner_manage = true,
  String        $runner_user,
  String        $runner_token,
  Array[String] $path = ['/usr/local/sbin','/usr/local/bin','/usr/sbin','/usr/bin','/sbin','/bin','/opt/puppetlabs/bin/'],
  String        $server_name = 'puppet.puppet.lan',
  Boolean       $server_autosign = true,
) {
  # Ensure class declares subordinate classes
  contain puppetserver::install
  contain puppetserver::config
  contain puppetserver::service
  contain puppetserver::implementation::runner
  contain puppetserver::implementation::installer
  contain puppetserver::implementation::uninstaller

  # Execute classes in order
  if $puppetserver::package_manage {
    anchor { '::puppetserver::begin': }
    -> Class['::puppetserver::install']
    -> Class['::puppetserver::config']
    -> Class['::puppetserver::implementation::runner']
    -> Class['::puppetserver::service']
    -> anchor { '::puppetserver::end': }
  }
}
