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
        $cfg_contents = @(EOT)
        Host github.com
          Hostname github.com
          User git
          IdentityFile /root/.ssh/id_control
        | EOT

        # Ensure root .ssh directory exists
        file { 'ensure that .ssh directory exists for root':
          ensure => directory,
          path   => '/root/.ssh/',
        }

        file { 'ensure known_hosts file exists for root':
          ensure => file,
          path   => '/root/.ssh/known_hosts',
          owner  => 'root',
          group  => 'root',
          mode   => '0600',
        }

        # Ensure github hostkey is known
        file_line { 'ensure github.com host key in known_hosts file':
          ensure => present,
          path   => '/root/.ssh/known_hosts',
          line   => 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl',
        }

        # Provision control repo access key
        file { 'provision control repo deploy key':
          ensure  => file,
          path    => '/root/.ssh/id_control',
          owner   => 'root',
          group   => 'root',
          mode    => '0600',
          content => $puppetserver::control_repo_key,
        }

        # Ensure the config file exists
        file { 'ensure config file exists':
          ensure => file,
          path   => '/root/.ssh/config',
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
        file { 'ensure config.d directory exists':
          ensure => directory,
          path   => '/root/.ssh/config.d',
          owner  => 'root',
          group  => 'root',
          mode   => '0700',
        }

        # Ensure the control repo configuration exists
        ~> file { 'ensure control repo configuration exists':
          ensure  => file,
          path    => '/root/.ssh/config.d/control-repo.conf',
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
          unless  => 'systemctl is-active puppetserver',
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
      'purged', 'absent': {
      }
      'disabled': {
      }
      default: {
        notify { "Unknown 'package_ensure' value ${puppetserver::package_ensure}": }
      }
    }
  }
}
