# File::      <tt>common.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (hpc-sysadmins@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
#
# ------------------------------------------------------------------------------
# = Class: multipath::common
#
# Base class to be inherited by the other multipath classes, containing the common code.
#
# Note: respect the Naming standard provided here[http://projects.puppetlabs.com/projects/puppet/wiki/Module_Standards]
# ------------------------------------------------------------------------------
# = Class: multipath::common
#
# Base class to be inherited by the other multipath classes
#
# Note: respect the Naming standard provided here[http://projects.puppetlabs.com/projects/puppet/wiki/Module_Standards]
class multipath::common {

    package { 'multipath':
        ensure => $multipath::ensure,
        name   => $multipath::package_name,
    }

    if $multipath::ensure == 'present' {
        $multipath_service_ensure = $multipath::service_ensure
        $multipath_service_enable = $multipath::service_enable
    } else {
        $multipath_service_ensure = 'stopped'
        $multipath_service_enable = false
    }

    service { 'multipath':
        ensure  => $multipath_service_ensure,
        enable  => $multipath_service_enable,
        name    => $multipath::service_name,
        require => Package['multipath'],
    }

    if $multipath::manage_rclocal {
        include ::rclocal
        rclocal::update { 'Increase timeout for FC':
            ensure  => $multipath::ensure,
            content => template('multipath/rc.local.access_timeout.erb'),
            order   => 20,
        }
    }

    # TODO: deal with ensure != 'present'
    concat { $multipath::configfile:
        warn    => false,
        owner   => $multipath::configfile_owner,
        group   => $multipath::configfile_group,
        mode    => $multipath::configfile_mode,
        require => Package['multipath'],
        notify  => Service['multipath'],
    }

    if $multipath::configfile_source != '' {
        # Use the source or the content as the reference for the /etc/multipath.conf
        concat::fragment { "${multipath::configfile}_full":
            target => $multipath::configfile,
            order  => '01',
            source => $multipath::configfile_source,
            notify => Service['multipath'],
        }
    }
    else
    {
        # Here, build the /etc/multipath.conf by fragments, starting from the
        # defaults settings (precised with the classe instanciation), the rest
        # beeing set by the following definitions:
        #    - multipath::device    (to define a device)
        #    - multipath::blacklist (to blacklist some device from multipathing)
        #    - multipath::path      (to define a path to a device)
        concat::fragment { "${multipath::configfile}_header":
            target  => $multipath::configfile,
            content => template('multipath/01-multipath.conf_header.erb'),
            order   => '01',
        }

        # 'devices' section
        concat::fragment { "${multipath::configfile}_devices_header":
            target => $multipath::configfile,
            source => 'puppet:///modules/multipath/10-multipath-devices_header',
            order  => '10',
        }
        concat::fragment { "${multipath::configfile}_devices_footer":
            target => $multipath::configfile,
            source => 'puppet:///modules/multipath/30-multipath-devices_footer',
            order  => '30',
        }

        # 'blacklist' section
        concat::fragment { "${multipath::configfile}_blacklist_header":
            target => $multipath::configfile,
            source => 'puppet:///modules/multipath/35-multipath-blacklist_header',
            order  => '35',
        }

        # 'blacklist_exceptions' section
        concat::fragment { "${multipath::configfile}_blacklist_exceptions_header":
            target => $multipath::configfile,
            source => 'puppet:///modules/multipath/45-multipath-blacklist_exceptions_header',
            order  => '45',
        }

        # 'multipaths' section
        concat::fragment { "${multipath::configfile}_multipaths_header":
            target => $multipath::configfile,
            source => 'puppet:///modules/multipath/55-multipath-multipaths_header',
            order  => '55',
        }
        concat::fragment { "${multipath::configfile}_multipaths_footer":
            target => $multipath::configfile,
            source => 'puppet:///modules/multipath/99-multipath-multipaths_footer',
            order  => '99',
        }

    }

}

