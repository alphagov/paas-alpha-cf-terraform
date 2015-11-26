#!/bin/bash

set -e # fail on error

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

get_bosh_secret() { ${SCRIPT_DIR}/val_from_yaml.rb templates/bosh-secrets.yml $1; }

TARGET_PLATFORM=$1
case $TARGET_PLATFORM in
  aws)
    ;;
  gce)
    ;;
  *)
    echo "Must specify the target platform: gce|aws"
    exit 1
    ;;
esac

# Include the terraform output variables
. $SCRIPT_DIR/terraform-outputs-${TARGET_PLATFORM}.sh

BOSH_ADMIN_USER=${BOSH_ADMIN_USER:-admin}
BOSH_IP=${BOSH_IP:-$terraform_output_bosh_ip}
BOSH_PORT=${BOSH_PORT:-25555}

# Dependencies versions
BOSH_INIT_VERSION=0.0.72
BOSH_INIT_URL=https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${BOSH_INIT_VERSION}-linux-amd64
SPIFF_VERSION=v1.0.7
SPIFF_URL=https://github.com/cloudfoundry-incubator/spiff/releases/download/${SPIFF_VERSION}/spiff_linux_amd64.zip
BOSH_CLI_VERSION=1.3056.0

# Constants
BOSH_MANIFEST=~/bosh-manifest.yml

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

  echo "Installing binaries: bosh-init, spiff, cf..."
  if [ ! -x /usr/local/bin/bosh-init ]; then
    sudo wget -q $BOSH_INIT_URL -O /usr/local/bin/bosh-init
    sudo chmod +x /usr/local/bin/bosh-init
  fi

  if [ ! -x /usr/local/bin/spiff ]; then
    wget -q $SPIFF_URL -O spiff_linux_amd64.zip
    sudo unzip -qo spiff_linux_amd64.zip -d /usr/local/bin
    sudo chmod +x /usr/local/bin/spiff
    rm spiff_linux_amd64.zip
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
    cd ~ && ./generate_bosh_manifest.sh $TARGET_PLATFORM > $BOSH_MANIFEST
    export BOSH_INIT_LOG_LEVEL=debug
    export BOSH_INIT_LOG_PATH=/tmp/bosh_init.log
    time bosh-init deploy $BOSH_MANIFEST
  fi

  if ! bosh_check_and_login; then
    echo "Failed to contact BOSH node $BOSH_IP:$BOSH_PORT after provisioning"
    return 1
  fi
}

install_dependencies
deploy_and_login_bosh
