# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver::config
class puppetserver::config {

  # Ensure the runner is configured
  Class['::puppetserver::implementation::runner']

  # Configure the server setting alt_dns_names
  exec { 'configure server setting alt_dns_names':
    command => "puppet config set dns_alt_names '${::puppetserver::server_name}' --section server",
    path    => $::puppetserver::path,
    unless  => "sudo /opt/puppetlabs/bin/puppet config print dns_alt_names --section server | grep -q ${::puppetserver::server_name}",
  }

  # Configure the server setting certname
  exec { 'configure server setting certname':
    command => "puppet config set certname '${::puppetserver::server_name}' --section server",
    path    => $::puppetserver::path,
    unless  => "sudo /opt/puppetlabs/bin/puppet config print certname --section server | grep -q ${::puppetserver::server_name}",
  }

  # Configure the server setting server
  exec { 'configure server setting server':
    command => "puppet config set server '${::puppetserver::server_name}' --section server",
    path    => $::puppetserver::path,
    unless  => "sudo /opt/puppetlabs/bin/puppet config print server --section server | grep -q ${::puppetserver::server_name}",
  }

  # Ensure the ca directory exists
  file { 'ensure that the ca directory exists inside of /etc/puppetlabs/puppetserver':
    ensure => directory,
    path   => '/etc/puppetlabs/puppetserver/ca',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0755',
  }

  # Configure the server setting cadir
  exec { 'configure server setting cadir':
    command => 'puppet config set cadir /etc/puppetlabs/puppetserver/ca --section server',
    path    => $::puppetserver::path,
    unless  => "sudo /opt/puppetlabs/bin/puppet config print cadir --section server | grep -q /etc/puppetlabs/puppetserver/ca",
  }

  # Configure the server setting ssldir
  exec { 'configure server setting ssldir':
    command => 'puppet config set ssldir /etc/puppetlabs/puppetserver/ca --section server',
    path    => $::puppetserver::path,
    unless  => "sudo /opt/puppetlabs/bin/puppet config print server --section server | grep -q /etc/puppetlabs/puppetserver/ca",
  }

  # Configure the hostname on the system to match the puppet servername
  exec { 'configure hostname on host to match puppet server name':
    command => "hostnamectl set-hostname ${::puppetserver::server_name}",
    path    => $::puppetserver::path,
    unless  => "sudo hostnamectl hostname | grep -q ${::puppetserver::server_name}",
  }

  # Setup the puppet server certificate authority
  exec { 'setup the puppet server certificate authority':
    command => 'puppetserver ca setup',
    path    => $::puppetserver::path,
    unless  => "test -f /etc/puppetlabs/puppetserver/certs/${::puppetserver::server_name}.pem",
  }

  if $::puppetserver::server_autosign {
    # Setup auto-signing of certificates
    file { 'enable puppet server autosigning':
      ensure  => file,
      path    => '/etc/puppetlabs/puppet/autosign.conf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => '*',
    }
  } else {
    # Disable auto-signing of certificates
    file { 'disable puppet server autosigning':
      ensure => absent,
      path   => '/etc/puppetlabs/puppet/autosign.conf',
    }
  }

  # Ensure the puppet server hosts entry exists
  file_line { 'ensure that the puppet server hosts entry exists':
    ensure => present,
    path   => '/etc/hosts',
    line   => "127.0.0.1\t${::puppetserver::server_name}\tpuppet",
    match  => '^127.0.0.1',
  }
}
