# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppetserver::implementation::runner
class puppetserver::implementation::runner {

  if $puppetserver::runner_manage {
    case $puppetserver::runner_ensure {
      'installed', 'present': {
        # Output notify message
        notify { 'Installing Control Repo Runner...': }

        # Ensure r10k can be run without a password. Add on it's own line so that any changes by the user aren't lost
        file_line { 'ensure r10k can be run as sudo without a password':
          ensure => present,
          path   => '/etc/sudoers',
          line   => "${::puppetserver::runner_user} ALL = NOPASSWD: /usr/bin/r10k",
          after  => "^${::puppetserver::runner_user} ALL",
        }

        # Setup r10k
        class { 'r10k':
          sources  => {
            'production' => {
              'remote'  => "ssh://${::puppetserver::control_repo_url}",
              'basedir' => '/etc/puppetlabs/code/environments/',
              'prefix'  => false,
            },
          },
          provider => 'puppet_gem',
        }

        # Ensure the runner directory exists
        file { 'ensure runner directory exists':
          ensure => directory,
          path   => '/opt/actions-runner',
          owner  => "${::puppetserver::runner_user}",
          group  => "${::puppetserver::runner_user}",
        }

        # Download the installer
        -> exec { 'download the github actions runner installer':
          command => 'curl -o /opt/actions-runner/actions-runner-linux-x64-2.299.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.299.1/actions-runner-linux-x64-2.299.1.tar.gz',
          path    => $::puppetserver::path,
          unless  => 'test -f /opt/actions-runner/.runner',
        }

        # Extract the runner
        -> exec { 'extract the github actions runner':
          command => 'tar xzf /opt/actions-runner/actions-runner-linux-x64-2.299.1.tar.gz -C /opt/actions-runner',
          path    => $::puppetserver::path,
          onlyif  => 'echo "147c14700c6cb997421b9a239c012197f11ea9854cd901ee88ead6fe73a72c74  /opt/actions-runner/actions-runner-linux-x64-2.299.1.tar.gz" | shasum -a 256 -c',
          unless  => 'test -f /opt/actions-runner/.runner',
        }

        # Configure the runner
        $runner_url = regsubst($puppetserver::control_repo_url, '.git$', '')
        exec { 'configure the github actions runner':
          command  => "/opt/actions-runner/config.sh --url ${$runner_url} --token ${::puppetserver::runner_token} --unattended",
          path     => $::puppetserver::path,
          provider => shell,
          user     => "${::puppetserver::runner_user}",
          unless   => 'test -f /opt/actions-runner/.runner',
        }

        # Install the runner service
        exec { 'install the github actions runner service':
          command => "/opt/actions-runner/svc.sh install ${::puppetserver::runner_user}",
          path    => $::puppetserver::path,
          cwd     => '/opt/actions-runner/',
          onlyif  => '/opt/actions-runner/svc.sh status | grep -q "not installed"',
        }

        # ensure runner service is running
        exec { 'ensure the github actions runner is running':
          command => '/opt/actions-runner/svc.sh start',
          path    => $::puppetserver::path,
          cwd     => '/opt/actions-runner/',
          unless  => 'sudo /opt/actions-runner/svc.sh status | grep -q "active (running)"',
        }
      }

      'purged', 'absent': {
        notify { 'Removing Control Repo Runner...': }

        # ensure runner service is uninstalled
        exec { 'ensure the github actions runner is uninstalled':
          command => '/opt/actions-runner/svc.sh uninstall',
          path    => $::puppetserver::path,
          cwd     => '/opt/actions-runner/',
          unless  => 'sudo /opt/actions-runner/svc.sh status | grep -q "not installed"',
        }

        # ensure runner directory is gone
        exec { 'ensure the github actions runner directory is removed':
          command => 'rm -rf /opt/actions-runner',
          path    => $::puppetserver::path,
          onlyif  => 'test -d /opt/actions-runner',
        }

        # Ensure r10k sudoers line is removed
        file_line { 'ensure r10k can be run as sudo without a password':
          ensure => absent,
          path   => '/etc/sudoers',
          line   => "${::puppetserver::runner_user} ALL = NOPASSWD: /usr/bin/r10k",
        }
      }

      'disabled': {
        notify { 'Disabling Control Repo Runner...': }

        # ensure runner service is not running
        exec { 'ensure the github actions runner is not running':
          command => '/opt/actions-runner/svc.sh stop',
          path    => $::puppetserver::path,
          cwd     => '/opt/actions-runner/',
          unless  => 'sudo /opt/actions-runner/svc.sh status | grep -q "inactive (dead)"',
        }
      }

      default: {
        notify { "Unknown 'runner_ensure' value ${puppetserver::runner_ensure}": }
      }
    }
  }


}
