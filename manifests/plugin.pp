#
# == Define kibana::plugin
#
#  Defined type to manage kibana plugins
#
define kibana::plugin(
  $source       = undef,
  $url          = undef,
  $ensure       = 'present',
  $install_root = $::kibana::install_path,
  $group        = $::kibana::group,
  $user         = $::kibana::user) {

  if ($source != undef) {
    # plugins must be formatted <org>/<plugin>/<version>
    $filenameArray = split($source, '/')
    $base_module_name = $filenameArray[-2]
  } elsif ($url != undef) {
    $base_module_name = $url
  }

  # borrowed heavily from https://github.com/elastic/puppet-elasticsearch/blob/master/manifests/plugin.pp
  $plugins_dir = "${install_root}/kibana/plugins"
  $install_cmd = "${install_root}/kibana/bin/kibana-plugin install ${base_module_name}"
  $uninstall_cmd = "${install_root}/kibana/bin/kibana-plugin remove ${title}"

  Exec {
    path      => [ '/bin', '/usr/bin', '/usr/sbin', "${install_root}/kibana/bin" ],
    cwd       => '/',
    user      => $user,
    tries     => 6,
    try_sleep => 10,
    timeout   => 600,
  }

  case $ensure {
    'installed', 'present': {
      $name_file_path = "${plugins_dir}/${title}/.name"
      exec {"install_plugin_${title}":
        command => $install_cmd,
        creates => $name_file_path,
        notify  => Service['kibana'],
        require => File[$plugins_dir],
      }
      file {$name_file_path:
        ensure  => file,
        content => $base_module_name,
        require => Exec["install_plugin_${title}"],
      }
    }
    'absent': {
      exec {"remove_plugin_${title}":
        command => $uninstall_cmd,
        onlyif  => "test -f ${name_file_path}",
        notify  => Service['kibana'],
      }
    }
    default: {
      fail("${ensure} is not a valid ensure command.")
    }
  }
}
