# File::      <tt>multipath-blacklist.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2011 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Defines: multipath::blacklist
#
# This definition configure a blacklist-specific setting for multipath.
# It is used to exclude specific device from inclusion in the multipath
# topology.
#
# == Pre-requisites
#
# * The class 'multipath' should have been instanciated
#
# == Parameters:
#
# [*ensure*]
#   default to 'present', can be 'absent'.
#   Default: 'present'
#
# [*content*]
#  Specify the contents of the blacklist entry as a string. Newlines, tabs,
#  and spaces can be specified using the escaped syntax (e.g., \n for a newline)
#
# [*source*]
#  Copy a file as the content of the blacklist entry.
#  Uses checksum to determine when a file should be copied.
#  Valid values are either fully qualified paths to files, or URIs. Currently
#  supported URI types are puppet and file.
#
# [*is_exception*]
#  Whether or not this defines a blacklist exception, which is used to revert
#  the actions of the blacklist section, ie to include specific device in the
#  multipath topology. This allows to selectively include devices
#  Default: false
#
# [*wwid*]
# Array of wwid: World Wide Identification of a device
#
# [*devnode*]
#  Array of product strings to blacklist for this vendor
#
# [*vendor*]
#   Vendor identifier.
#
# [*product*]
#  Product identifier
##
# == Requires:
#
# n/a
#
# == Sample usage:
#
#     include multipath
#
# You can then specialize the various aspects of the configuration,
# for instance:
#
#      multipath::blacklist { '':
#          ensure => 'present',
#
#      }
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# [Remember: No empty lines between comments and class definition]
#
define multipath::blacklist (
    $ensure       = 'present',
    $is_exception = false,
    $content      = '',
    $source       = '',
    $wwid         = [],
    $devnode      = [],
    $vendor       = '',
    $product      = ''
)
{

    # $name is provided by define invocation
    $blacklist_name = $name

    if $multipath::configfile_source != '' {
        fail('multipath::blacklist cannot be used when the configfile_source attribute has been set')
    }

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("multipath::blacklist 'ensure' parameter must be set to either 'absent' or 'present'")
    }

    if ($multipath::ensure != $ensure) {
        if ($multipath::ensure != 'present') {
            fail("Cannot configure a multipath blacklist '${blacklist_name}' as multipath::ensure is NOT set to present (but ${multipath::ensure})")
        }
    }

    $exception_suffix = $is_exception ? {
        true    => '_exceptions',
        default => ''
    }
    $order = $is_exception ? {
        false   => '40',
        default => '50'
    }


    # if content is passed, use that, else if source is passed use that
    $real_content = $content ? {
        '' => $source ? {
            ''      => template('multipath/40-multipath-blacklist_entry.erb'),
            default => undef
        },
        default => $content
    }
    $real_source = $source ? {
        '' => undef,
        default => $content ? {
            ''      => $source,
            default => undef
        }
    }

    concat::fragment { "${multipath::configfile}_blacklist${exception_suffix}_${name}":
        target  => $multipath::configfile,
        order   => $order,
        content => $real_content,
        source  => $real_source,
        notify  => Service['multipath'],
    }
}





