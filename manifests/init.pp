# File::      <tt>init.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (hpc-sysadmins@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
#
# ------------------------------------------------------------------------------
# = Class: multipath
#
# Configure multipath to detect multiple paths to devices for fail-over or
# performance reasons and coalesces them.
# For the moment, it is only used to configure multipathing on a disk
# bay. (tested on an NFS server and Lustre servers (OSS, MDS), each of them
# interfacing a Nexsan Disk enclosure).
#
# == Parameters:
#
# $ensure:: *Default*: 'present'. Ensure the presence (or absence) of multipath
# $package_name:: Override package name
# $service_ensure:: *Default*: 'running'. Ensure that multipath daemon is running
# $service_enable:: *Default*: 'true'. Ensure that multipath daemon would be started on boot
# $service_name:: Override package name
# $service_name:: Override package name
# $configfile_source:: *Default*: ''. If set, the source of the multipath.conf file
# $configfile:: Override default configfile path
# $FC_access_timeout:: *Default*: 150. Timeout to access a volume by Fiber Channel
# $polling_interval:: *Default*: 5. Interval between two path checks in seconds
# $verbosity:: *Default*: 2.
# $selector:: *Default*: round-robin 0. Default path selector algorithm to use
# $path_grouping_policy:: *Default*: multibus. Default path grouping policy to
#     apply to unspecified multipaths. Possible values include:
#     - failover           = 1 path per priority group
#     - multibus           = all valid paths in 1 priority group
#     - group_by_serial    = 1 priority group per detected serial number
#     - group_by_prio      = 1 priority group per path priority value
#     - group_by_node_name = 1 priority group per target node name
# $getuid_callout::  program and args to callout to obtain a unique path identifier.
# $prio_callout:: Default function to call to obtain a path priority value
# $path_checker:: Default method used to determine the paths' state
# $failback:: *Default*: manual. Tells the daemon to manage path group failback,
#     or not to. Possible values: manual|immediate|n > 0.
#     0 means immediate failback, values >0 means deffered failback expressed in seconds.
# $rr_weight:: *Default*: uniform. Possible values: priorities|uniform. if set
#     to priorities, the multipath configurator will assign path weights as:
#                     "path prio * rr_min_io"
# $rr_min_io:: *Default*: 1000
# $no_path_retry::  Tells the number of retries until disable queueing, or
#     "fail" means immediate failure (no queueing) while "queue" means never stop
#     queueing. Possible values: queue|fail|n (>0)
# $user_friendly_names:: *Default*: no. If set to "yes", using the bindings file
#     /var/lib/multipath/bindings to assign a persistent and unique alias to the
#     multipath, in the form of mpath<n>. If set to "no", use the WWID as the
#     alias. In either case, this be will be overriden by any specific aliases
#     in this file.
# $max_fds:: Sets the maximum number of open file descriptors for the multipathd
#     process. Possible values: max|n > 0
# $manage_rclocal:: *Default*: true. Allow rclocal to be disabled for newer systems
#
# == Actions:
#
# Install and configure multipath
#
# == Requires:
#
# n/a
#
# == Sample Usage:
#
#     import multipath
#
# You can then specialize the various aspects of the configuration,
# for instance:
#
#         class { 'multipath':
#             ensure => 'present'
#         }
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
#
# [Remember: No empty lines between comments and class definition]
#
class multipath(
    $ensure                 = $multipath::params::ensure,
    $package_name           = $multipath::params::package_name,
    $service_ensure         = $multipath::params::service_ensure,
    $service_enable         = $multipath::params::service_enable,
    $service_name           = $multipath::params::service_name,
    $access_timeout         = $multipath::params::access_timeout,
    $configfile_source      = '',
    $configfile             = $multipath::params::configfile,
    Enum['strict','no','yes','greedy','smart'] $find_multipaths = 'no',
    Integer $polling_interval = 5,
    Enum['round-robin 0','queue-length 0','service-time 0'] $selector = 'service-time 0',
    Enum['failover','multibus','group_by_serial','group_by_prio','group_by_node_name'] $path_grouping_policy = 'multibus',
    $getuid_callout         = $multipath::params::getuid_callout,
    $prio_callout           = $multipath::params::prio_callout,
    $prio                   = $multipath::params::prio,
    $path_checker           = $multipath::params::path_checker,
    $failback               = $multipath::params::failback,
    $no_path_retry          = $multipath::params::no_path_retry,
    $rr_weight              = $multipath::params::rr_weight,
    $rr_min_io              = $multipath::params::rr_min_io,
    $user_friendly_names    = $multipath::params::user_friendly_names,
    $max_fds                = $multipath::params::max_fds,
    Boolean $manage_rclocal = true,
)
inherits multipath::params
{

    info ("Configuring multipath package (with ensure = ${ensure})")

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("Invalid multipath 'ensure' parameter")
    }
    if ! ($path_grouping_policy in [ 'failover', 'multibus', 'group_by_serial', 'group_by_prio', 'group_by_node_name']) {
        fail("Invalid multipath 'path_grouping_policy' parameter")
    }
    if ($selector != 'round-robin 0') {
        fail("Invalid multipath 'selector' parameter")
    }
    if ! ($path_checker in [ 'readsector0', 'tur', 'emc_clariion', 'hp_sw', 'directio', 'rdac', 'cciss_tur']) {
        fail("Invalid multipath 'path_checker' parameter")
    }

    case $::operatingsystem {
        'debian', 'ubuntu':         { include ::multipath::common::debian }
        'redhat', 'fedora', 'centos': { include ::multipath::common::redhat }
        default: {
            fail("Module ${module_name} is not supported on ${::operatingsystem}")
        }
    }
}
