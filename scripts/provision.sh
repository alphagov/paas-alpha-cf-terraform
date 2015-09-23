#!/bin/bash

set -e # fail on error
# Other config
export PATH=$PATH:/usr/local/bin/bosh

# Preinstallation of packages
function install_dependencies {
  PACKAGES="
    build-essential
    git
    zlibc
    zlib1g-dev
    ruby
    ruby-dev openssl
    libxslt-dev
    libxml2-dev
    libssl-dev
    libreadline6
    libreadline6-dev
    libyaml-dev
    libsqlite3-dev
    sqlite3
    dstat
    unzip
  "

  GEMS="
    bosh_cli:1.3056.0
  "

  echo "Installing system packages..."
  if ! dpkg -l $PACKAGES > /dev/null 2>&1; then
    sudo apt-get -y update
    sudo apt-get install -y $PACKAGES
  fi

  echo "Installing gem packages..."
  for gem in $GEMS; do
    local gem_name=$(echo $gem | cut -f 1 -d : )
    local gem_version=$(echo $gem | cut -f 2 -d : )
    if ! gem list | grep -q "$gem_name ($gem_version)"; then
      sudo gem install $gem_name ${gem_version:+--version $gem_version} --no-ri --no-rdoc
    fi
  done

  echo "Installing binaries: bosh-init, spiff..."
  if [ ! -x /usr/local/bin/bosh-init ]; then
    sudo wget -q https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.72-linux-amd64 -O /usr/local/bin/bosh-init
    sudo chmod +x /usr/local/bin/bosh-init
  fi

  if [ ! -x /usr/local/bin/spiff ]; then
    wget -q https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
    sudo unzip -qo spiff_linux_amd64.zip -d /usr/local/bin
    sudo chmod +x /usr/local/bin/spiff
  fi

}
install_dependencies
