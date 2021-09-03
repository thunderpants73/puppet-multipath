# File::      <tt>multipath-path.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2011 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Defines: multipath::path
#
# This definition configure a multipath-specific setting
# The name of this definition is set to the wwid attribute, unless this
# parameter is passed as an argument.
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
#  Specify the contents of the path entry as a string. Newlines, tabs,
#  and spaces can be specified using the escaped syntax (e.g., \n for a newline)
#
# [*source*]
#  Copy a file as the content of the path entry.
#  Uses checksum to determine when a file should be copied.
#  Valid values are either fully qualified paths to files, or URIs. Currently
#  supported URI types are puppet and file.
#
# [*devalias*]
#  (Optional) symbolic name for the multipath map.
#
# The following attributes are optional; if not set the default values are taken
# from the defaults section:
#              path_grouping_policy
#              path_selector
#              failback
#              rr_weight
#              no_path_retry
#              rr_min_io
#
# See the 'multipath' for details about these parameters
#
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
#      multipath::path { ''
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
define multipath::path (
    $ensure            = 'present',
    $devalias          = '',
    $content           = '',
    $source            = '',
    $path_grouping_policy = $multipath::path_grouping_policy,
    $prio_callout      = $multipath::prio_callout,
    $path_selector     = $multipath::selector,
    $failback          = $multipath::failback,
    $no_path_retry     = $multipath::no_path_retry,
    $rr_weight         = $multipath::rr_weight,
    $rr_min_io         = $multipath::rr_min_io
)
{

    # $name is provided by define invocation and is should be set to the
    # vendor, unless the vendor attribute is set
    $wwid = $name

    if $multipath::configfile_source != '' {
        fail('multipath::path cannot be used when the configfile_source attribute has been set')
    }

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("multipath::path 'ensure' parameter must be set to either 'absent' or 'present'")
    }

    if ($multipath::ensure != $ensure) {
        if ($multipath::ensure != 'present') {
            fail("Cannot configure a multipath path '${wwid}' as multipath::ensure is NOT set to present (but ${multipath::ensure})")
        }
    }

    # if content is passed, use that, else if source is passed use that
    $real_content = $content ? {
        '' => $source ? {
            ''      => template('multipath/60-multipath-path_entry.erb'),
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

    concat::fragment { "${multipath::configfile}_multipath_${wwid}":
        target  => $multipath::configfile,
        order   => '60',
        content => $real_content,
        source  => $real_source,
        notify  => Service['multipath'],
    }
}





