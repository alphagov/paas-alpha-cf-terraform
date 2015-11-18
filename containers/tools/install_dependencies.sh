#!/bin/bash -e
PACKAGES="
  openssh-client
  build-essential
  git
  golang
  zlibc
  zlib1g-dev
  ruby
  ruby-dev
  openssl
  libxslt1-dev
  libxml2-dev
  libssl-dev
  libreadline6
  libreadline6-dev
  libyaml-dev
  libsqlite3-dev
  sqlite3
  dstat
  unzip
  bundler
  jq
  wget
"

# For go 1.5
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository -y ppa:ubuntu-lxc/lxd-stable

apt-get update
apt-get -y upgrade
apt-get install -y --no-install-recommends $PACKAGES

BOSH_INIT_VERSION=0.0.72
BOSH_INIT_URL=https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${BOSH_INIT_VERSION}-linux-amd64
SPIFF_VERSION=v1.0.7
SPIFF_URL=https://github.com/cloudfoundry-incubator/spiff/releases/download/${SPIFF_VERSION}/spiff_linux_amd64.zip
CF_CLI_VERSION=6.12.3

export BUNDLE_GEMFILE=/tmp/Gemfile
echo "Installing gem packages..."
bundle install

echo "Installing binaries: bosh-init, spiff, cf..."
wget -q $BOSH_INIT_URL -O /usr/local/bin/bosh-init
chmod +x /usr/local/bin/bosh-init

wget -q $SPIFF_URL -O spiff_linux_amd64.zip
unzip -qo spiff_linux_amd64.zip -d /usr/local/bin
chmod +x /usr/local/bin/spiff
rm spiff_linux_amd64.zip

wget -q -O /tmp/cf-cli_${CF_CLI_VERSION}_amd64.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${CF_CLI_VERSION}&source=github-rel"
dpkg -i /tmp/cf-cli_${CF_CLI_VERSION}_amd64.deb > /dev/null
rm /tmp/cf-cli_${CF_CLI_VERSION}_amd64.deb
