# File::      <tt>params.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (hpc-sysadmins@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
#
# ------------------------------------------------------------------------------
# = Class: multipath::params
#
# In this class are defined as variables values that are used in other
# multipath classes.
# This class should be included, where necessary, and eventually be enhanced
# with support for more OS
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# The usage of a dedicated param classe is advised to better deal with
# parametrized classes, see
# http://docs.puppetlabs.com/guides/parameterized_classes.html
#
# [Remember: No empty lines between comments and class definition]
#
class multipath::params {

    ######## DEFAULTS FOR VARIABLES USERS CAN SET ##########################
    # (Here are set the defaults, provide your custom variables externally)
    # (The default used is in the line with '')
    ###########################################

    # ensure the presence (or absence) of multipath package
    $ensure = 'present'

    # ensure if multipath service is running or stopped
    $service_ensure = 'running'

    # check if multipath service should be started at boot
    $service_enable = true

    # timeout to access a volume by Fiber Channel
    $access_timeout = '45'

    ### Those are the values put in the multipath.conf file

    # Interval between two path checks in seconds
    $polling_interval = '5'

    # Default path selector algorithm to use. These algorithms are offered by
    # the kernel multipath target.
    # Currently support a single value: "round-robin 0"
    $selector = 'round-robin 0'

    # Default path grouping policy to apply to unspecified multipaths.
    # Possible values:
    # - failover           = 1 path per priority group
        # - multibus           = all valid paths in 1 priority group
        # - group_by_serial    = 1 priority group per detected serial number
        # - group_by_prio      = 1 priority group per path priority value
        # - group_by_node_name = 1 priority group per target node name
    $path_grouping_policy = 'multibus'

    # Default program and args to callout to obtain a unique path
    # identifier. Absolute path required.
    $getuid_callout = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/ => '/lib/udev/scsi_id --whitelisted --device=/dev/%n',
        /(?i-mx:redhat|centos)/ => $::operatingsystemmajrelease ? {
            6       => '/lib/udev/scsi_id --whitelisted --device=/dev/%n',
            default => '/sbin/scsi_id -g -u -s /block/%n'
        },
        default                 => '/sbin/scsi_id -g -u -s /block/%n'
    }

    # Default function to call to obtain a path priority value
    # The ALUA bits in SPC-3 provide an exploitable prio value for example.
    # Use $prio_callout in RedHat-like systems, and $prio on Debian-like
    # systems.
    $prio_callout  = 'none'
    $prio          = 'alua /dev/%n'

    # Default method used to determine the paths' state.
    # Possibles values: readsector0|tur|emc_clariion|hp_sw|directio|rdac|cciss_tur
    $path_checker = 'readsector0'

    # Tell the daemon to manage path group failback, or not to.
    # - 0 means immediate failback,
    # - values >0 means deffered failback expressed in seconds
    # Possible values: manual|immediate|n > 0
    $failback = 'manual'

    # Tell the number of retries until disable queueing (n>0), or:
    # - "fail" means immediate failure (no queueing),
    # - "queue" means never stop queueing
    # Possible values  : queue|fail|n > 0
    $no_path_retry = '0'

    # Number of IO to route to a path before switching to the next in the same
    # path group
    $rr_min_io = '1000'

    # if set to priorities, the multipath configurator will assign path weights
    # as  "path prio * rr_min_io"
    # Possible values  : priorities|uniform
    $rr_weight = 'uniform'

    # Whether or not to use user-friendly names.
    # If set to "yes", using the bindings file /var/lib/multipath/bindings to
    # assign a persistent and unique alias to the multipath, in the form of
    # mpath<n>. If set to "no" use the WWID as the alias.
    # Possible values: yes|no
    $user_friendly_names  = 'no'

    # Sets the maximum number of open file descriptors for the multipathd
    # process. Possible values: max|n > 0. Unset by default.
    $max_fds = ''


    #### MODULE INTERNAL VARIABLES  #########
    # (Modify to adapt to unsupported OSes)
    #######################################
    $package_name = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/ => 'multipath-tools',
        default => 'device-mapper-multipath'
    }

    $service_name = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/ => 'multipath-tools',
        default                 => 'multipathd'
    }
    # used for pattern in a service ressource
    $processname = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/ => 'multipath-tools',
        default                 => 'multipathd'
    }
    $hasstatus = $::operatingsystem ? {
        /(?i-mx:ubuntu|debian)/        => false,
        /(?i-mx:centos|fedora|redhat)/ => true,
        default => true,
    }
    $hasrestart = $::operatingsystem ? {
        default => true,
    }


    $configfile = $::operatingsystem ? {
        default => '/etc/multipath.conf.new',
    }

    $configfile_mode = $::operatingsystem ? {
        default => '0644',
    }

    $configfile_owner = $::operatingsystem ? {
        default => 'root',
    }

    $configfile_group = $::operatingsystem ? {
        default => 'root',
    }

}

