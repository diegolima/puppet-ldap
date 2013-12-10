class ldap::nss(
  $base         = 'dc=alkivi,dc=fr',
  $uri          = 'ldap://127.0.0.1',
  $ldap_version = 3,
  $pam_password = 'crypt',
  $base_passwd  = 'ou=people',
  $base_shadow  = 'ou=people',
  $base_group   = 'ou=groups',
) {

  $package_name    = $::osfamily ? {
    'Debian' => 'libnss-ldap',
    'RedHat' => 'nss-pam-ldapd',
  }
  $rootbinddn      = "cn=admin,${base}"
  $nss_base_passwd = "${base_passwd},${base}?sub"
  $nss_base_shadow = "${base_shadow},${base}?sub"
  $nss_base_group  = "${base_group},${base}?sub"

  File {
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$package_name]
  }

  package { $package_name:
    ensure => installed,
  }


  if $osfamily == 'Debian' {
    file { '/etc/libnss-ldap.conf':
      content => template('ldap/libnss-ldap.conf.erb')
    }
  
    exec { 'libnss-ldap.secret':
      command  => '/bin/cp /root/.passwd/ldap/admin /etc/libnss-ldap.secret && chmod 600 /etc/libnss-ldap.secret',
      creates  => '/etc/libnss-ldap.secret',
      provider => 'shell',
      path     => ['/bin', '/sbin', '/usr/bin'],
      require  => Package[$package_name],
    }
  }
  elsif $osfamily == 'RedHat' {
    file { '/etc/nslcd.conf':
      content => template('ldap/nslcd.conf.erb'),
      require => Package[$package_name],
    }

    service { 'nslcd':
      ensure => running,
    }
  }

  exec { 'update-nsswitch':
    command  => 'sed -i "s/passwd:\(.*\)/passwd:\1 ldap/" /etc/nsswitch.conf && sed -i "s/group:\(.*\)/group:\1 ldap/" /etc/nsswitch.conf && sed -i "s/shadow:\(.*\)/shadow:\1 ldap/" /etc/nsswitch.conf',
    provider => 'shell',
    path     => ['/bin', '/sbin', '/usr/bin'],
    require  => Package[$package_name],
    unless   => 'grep -q ldap /etc/nsswitch.conf',
  }




}

