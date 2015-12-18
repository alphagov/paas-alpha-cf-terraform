#!/bin/bash

set -e # fail on error

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

get_bosh_secret() { ${SCRIPT_DIR}/val_from_yaml.rb ~/outputs/bosh-secrets.yml $1; }

# Include the terraform output variables
. outputs/terraform-outputs.sh

BOSH_ADMIN_USER=${BOSH_ADMIN_USER:-admin}
BOSH_IP=${BOSH_IP:-$terraform_output_bosh_ip}
BOSH_PORT=${BOSH_PORT:-25555}

# Dependencies versions
BOSH_INIT_VERSION=0.0.72
BOSH_INIT_URL=https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${BOSH_INIT_VERSION}-linux-amd64
SPRUCE_VERSION=v0.13.0
SPRUCE_URL=https://github.com/geofffranks/spruce/releases/download/${SPRUCE_VERSION}/spruce_0.13.0_linux_amd64.tar.gz
BOSH_CLI_VERSION=1.3056.0

# Constants
BOSH_MANIFEST=~/outputs/bosh-manifest.yml

export BUNDLE_GEMFILE=$SCRIPT_DIR/Gemfile
BOSH_CLI="bundle exec bosh"

# Other config
export PATH=$PATH:/usr/local/bin

# Preinstallation of packages
install_dependencies() {
  PACKAGES="
    build-essential
    git
    zlibc
    zlib1g-dev
    ruby
    ruby-dev openssl
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
  "

  echo "Installing system packages..."
  if dpkg-query -W -f='${Package} ${Status}\n' $PACKAGES 2>&1 | grep -v 'ok installed' | grep  '^..*$'; then
    sudo apt-get -y update
    sudo apt-get install -y $PACKAGES
  fi

  echo "Installing gem packages..."
  bundle install --quiet

  echo "Installing binaries: bosh-init"
  if [ ! -x /usr/local/bin/bosh-init ]; then
    sudo wget -q $BOSH_INIT_URL -O /usr/local/bin/bosh-init
    sudo chmod +x /usr/local/bin/bosh-init
  fi

  echo "Installing binaries: spruce"
  if [ ! -x /usr/local/bin/spruce ]; then
    wget -q $SPRUCE_URL -O spruce_linux_amd64.tar.gz
    sudo tar -xf spruce_linux_amd64.tar.gz -C /usr/local/bin/ --strip-components=1
    sudo chmod +x /usr/local/bin/spruce
    rm spruce_linux_amd64.tar.gz
  fi
}

# Bosh
bosh_login() {
  BOSH_ADMIN_PASS=$(get_bosh_secret secrets/bosh_admin_password)
  echo "Login to bosh $BOSH_IP:$BOSH_PORT"
  echo -e "${BOSH_ADMIN_USER}\n${BOSH_ADMIN_PASS}" | \
    $BOSH_CLI target $BOSH_IP:$BOSH_PORT || return 1
  echo -e "${BOSH_ADMIN_USER}\n${BOSH_ADMIN_PASS}" | \
    $BOSH_CLI login
}

bosh_check_and_login() {
  echo "Checking BOSH connection on $BOSH_IP:$BOSH_PORT"
  # Try to connect to the TCP port with 5s timeout
  nc -z -w 5 $BOSH_IP $BOSH_PORT || return 1

  # login to bosh director
  bosh_login || return 1

  # do a bosh status to check health
  $BOSH_CLI status > /dev/null || return 1
}

deploy_and_login_bosh() {
  if bosh_check_and_login; then
    echo "MicroBOSH up and running, not updating. Run 'bosh-init deploy $BOSH_MANIFEST' to rerun deploy manually."
  else
    echo "MicroBOSH node in $BOSH_IP:$BOSH_PORT is not configured or responding. Deploying it with bosh-init."
    export BOSH_INIT_LOG_LEVEL=debug
    export BOSH_INIT_LOG_PATH=/tmp/bosh_init.log
    ./scripts/generate_bosh_manifest.sh > $BOSH_MANIFEST
    time bosh-init deploy $BOSH_MANIFEST
  fi

  if ! bosh_check_and_login; then
    echo "Failed to contact BOSH node $BOSH_IP:$BOSH_PORT after provisioning"
    return 1
  fi
}

install_dependencies
deploy_and_login_bosh
