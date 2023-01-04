# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver::implementation::installer
class puppetserver::implementation::installer {

  $cfg_contents = @(EOT)
  Host github.com
    Hostname github.com
    User git
    IdentityFile /root/.ssh/id_control
  | EOT

  # Ensure github hostkey is known
  file_line { 'ensure github.com host key in known_hosts file':
    ensure => present,
    path   => '/root/.ssh/known_hosts',
    line   => 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl',
  }

  # Provision control repo access key
  file { '/root/.ssh/id_control':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $puppetserver::control_repo_key,
  }

  # Ensure the config file exists
  file { 'root/.ssh/config':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  # Ensure the config file has the include line for config.d
  -> file_line { 'ensure include line for config.d directory exists':
    ensure => present,
    path   => '/root/.ssh/config',
    line   => 'Include ~/.ssh/config.d/*',
  }

  # Ensure the config.d directory exists
  file { '/root/.ssh/config.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # Ensure the control repo configuration exists
  -> file { '/root/.ssh/config.d/control-repo.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $cfg_contents,
  }

  # Ensure that the puppet apt source is configured
  apt::source { 'puppet-7':
    comment  => 'Puppet 7 Mirror',
    location => 'http://apt.puppetlabs.com',
    repos    => 'puppet7',
    release  => 'focal',
    include  => {
      'deb' => true,
    },
  }

  # Ensure apt is updated
  ~> exec { 'run apt update after adding puppet7 source':
    command => 'apt update',
    path    => $::puppetserver::path,
    unless  => 'sudo systemctl is-active puppetserver',
  }

  # Ensure puppet server is installed
  package { 'puppetserver':
    ensure => installed,
  }

  # Ensure faraday is installed as it is used by r10k
  exec { 'install faraday gem v2.1.0':
    command => 'gem install faraday-net_http -v 2.1.0',
    path    => '/opt/puppetlabs/puppet/bin/',
    unless  => '/opt/puppetlabs/puppet/bin/gem list -i "^faraday-net_http$"',
  }

  # Ensure r10k is installed
  exec { 'install r10k gem v3.14.2':
    command => 'gem install r10k -v 3.14.2',
    path    => '/opt/puppetlabs/puppet/bin/',
    unless  => '/opt/puppetlabs/puppet/bin/gem list -i "^r10k$"',
  }
}
