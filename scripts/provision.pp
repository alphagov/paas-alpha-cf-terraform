$bosh_init_version='0.0.72'
$bosh_init_url="https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${bosh_init_version}-linux-amd64"

$spiff_version='v1.0.7'
# NOTE: download_uncompress does not support https
$spiff_url="http://github.com/cloudfoundry-incubator/spiff/releases/download/${spiff_version}/spiff_linux_amd64.zip"

$cf_cli_version='6.12.3'

$packages = [
  'build-essential',
  'git',
  'zlibc',
  'zlib1g-dev',
  'openssl',
  'libxslt1-dev',
  'libxml2-dev',
  'libssl-dev',
  'libreadline6',
  'libreadline6-dev',
  'libyaml-dev',
  'libsqlite3-dev',
  'sqlite3',
  'dstat',
  'jq',
]


# Actions start from here.
package { $packages:
  ensure => 'installed',
}

class { 'ruby':
  gems_version  => 'latest'
}

bundler::install { '/home/ubuntu/scripts':
  user       => 'ubuntu',
  group      => 'users',
  deployment => true,
  without    => 'development test doc',
}

# Install required binaries
notify {'Installing binaries: bosh-init':}

include wget
wget::fetch { 'bosh-init':
  source    => $bosh_init_url,
  destination => '/usr/local/bin/bosh-init',
}

file { '/usr/local/bin/bosh-init':
  path      => '/usr/local/bin/bosh-init',
  mode      => '0755',
}

download_uncompress {'spiff':
   distribution_name  => $spiff_url,
   dest_folder   => '/usr/local/bin/',
   creates       => "/usr/local/bin/spiff",
   uncompress    => 'zip',
}

file { '/usr/local/bin/spiff':
  path      => '/usr/local/bin/spiff',
  mode      => '0755',
}

wget::fetch { 'cf-client':
  source      => "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_version}&source=github-rel",
  destination => "/tmp/cf-cli_${cf_cli_cersion}_amd64.deb",
}

package { 'cf-cli' :
  provider    => dpkg,
  ensure      => latest,
  source      => "/tmp/cf-cli_${cf_cli_cersion}_amd64.deb",
}

