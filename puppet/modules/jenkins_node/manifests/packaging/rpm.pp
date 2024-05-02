# All RPM packaging tools
# @api private
class jenkins_node::packaging::rpm (
  Stdlib::Absolutepath $homedir,
  String $user,
  Stdlib::Absolutepath $workspace,
) {
  $is_el7 = $facts['os']['release']['major'] == '7'
  $ansible_python_version = if $facts['os']['release']['major'] == '8' { 'python3.11' } else { 'python3' }

  package { ['rpm-build', 'createrepo', 'copr-cli', 'rpmlint']:
    ensure => installed,
  }

  unless $is_el7 {
    yumrepo { 'git-annex':
      name     => 'git-annex',
      baseurl  => 'https://downloads.kitenet.net/git-annex/linux/current/rpms/',
      enabled  => '1',
      gpgcheck => '0',
    } ->
    package { ['git-annex-standalone']:
      ensure => installed,
    }
  } else {
    package { ['git-annex', 'pyliblzma']:
      ensure => installed,
    }
  }

  $obal_packages = [
    $ansible_python_version,
    "${ansible_python_version}-pyyaml",
    "${ansible_python_version}-setuptools",
  ]
  $foreman_rel_eng_packages = [
    'python3-pyyaml',
  ]

  ensure_packages($obal_packages + $foreman_rel_eng_packages)

  # koji
  file { "${homedir}/bin":
    ensure => absent,
  }

  file { "${homedir}/.koji":
    ensure => absent,
  }

  file { "${homedir}/.koji/katello-config":
    ensure => absent,
  }

  file { "${homedir}/.koji/config":
    ensure => absent,
  }

  file { "${homedir}/.katello.cert":
    ensure => absent,
  }

  file { "${homedir}/.katello-ca.cert":
    ensure => absent,
  }

  # specs-from-koji
  package { ['scl-utils-build', 'rpmdevtools']:
    ensure => present,
  }

  # Needed for EL8 repoclosure on EL7 nodes
  if $facts['os']['family'] == 'RedHat' {
    if $facts['os']['name'] == 'RedHat' {
      yumrepo { 'rhel-7-server-rhui-extras-rpms':
        enabled => true,
        before  => Package['dnf'],
      }
    } else {
      yumrepo { 'rhel-7-server-rhui-extras-rpms':
        ensure => absent,
      }
    }
  }

  package { ['dnf', 'dnf-plugins-core']:
    ensure => present,
  }

  secure_ssh::rsync::uploader_key { 'yumrepostage':
    user       => $user,
    dir        => "${workspace}/staging_key",
    manage_dir => true,
  }

  include rsync

  secure_ssh::rsync::uploader_key { 'yumstage':
    ensure => 'absent',
    user   => $user,
  }
}
