#!/bin/bash

set -e # fail on error

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

get_cf_secret() { ${SCRIPT_DIR}/val_from_yaml.rb templates/cf-secrets.yml $1; }
get_bosh_secret() { ${SCRIPT_DIR}/val_from_yaml.rb templates/bosh-secrets.yml $1; }
get_output() { ${SCRIPT_DIR}/val_from_yaml.rb templates/outputs/terraform-outputs-${TARGET_PLATFORM}.yml $1; }

# Read the platform configuration
TARGET_PLATFORM=$1
case $TARGET_PLATFORM in
  aws)
    STEMCELL=light-bosh-stemcell-3074-aws-xen-hvm-ubuntu-trusty-go_agent.tgz
    ;;
  gce)
    STEMCELL=light-bosh-stemcell-3074-google-kvm-ubuntu-trusty-go_agent.tgz
    STEMCELL_URL=http://storage.googleapis.com/gce-bosh-stemcells/$STEMCELL
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

# Git cf-release to clone
CF_RELEASE=215
CF_RELEASE_GIT_URL=https://github.com/alphagov/cf-release.git
CF_RELEASE_REVISION='cf_jobs_without_static_ips_dependencies_v215_103419194_with_dea_next_mtu'

# Releases to upload
BOSH_RELEASES="
cf,215,https://bosh.io/d/github.com/cloudfoundry/cf-release?v=$CF_RELEASE
elasticsearch,0.1.0,https://github.com/hybris/elasticsearch-boshrelease/releases/download/v0.1.0/elasticsearch-0.1.0.tgz
"

# Dependencies versions
BOSH_INIT_VERSION=0.0.72
BOSH_INIT_URL=https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${BOSH_INIT_VERSION}-linux-amd64
SPIFF_VERSION=v1.0.7
SPIFF_URL=https://github.com/cloudfoundry-incubator/spiff/releases/download/${SPIFF_VERSION}/spiff_linux_amd64.zip
BOSH_CLI_VERSION=1.3056.0
CF_CLI_VERSION=6.12.3

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

  if ! cf_version_orig=`dpkg-query -W cf-cli 2>/dev/null` || [[ "${cf_version_orig}" != *"${CF_CLI_VERSION}"* ]]; then
    sudo dpkg -r cf-cli 2>/dev/null
    wget -q -O /tmp/cf-cli_${CF_CLI_VERSION}_amd64.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${CF_CLI_VERSION}&source=github-rel"
    sudo dpkg -i /tmp/cf-cli_${CF_CLI_VERSION}_amd64.deb > /dev/null
    rm /tmp/cf-cli_${CF_CLI_VERSION}_amd64.deb
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

git_clone() {
  local url=$1
  local revision=$2
  path=$(echo ${url} | sed "s|.*/||;s|.git||")

  if [ ! -d ~/${path}/.git ]; then
    rm -rf ~/${path}
    git clone -q ${url} ~/${path}
  else
    cd ~/${path}
    git remote set-url origin ${url}
    git fetch -q
  fi

  cd ~/${path}
  git checkout -q ${revision}
}

clone_and_update_cf_release(){
  # Git clone and upload release
  echo "Updating ~/cf-release from $CF_RELEASE_GIT_URL:$CF_RELEASE_REVISION"

  if [ ! -d ~/cf-release/.git ]; then
    rm -rf ~/cf-release
    git clone -q $CF_RELEASE_GIT_URL ~/cf-release
  else
    cd ~/cf-release
    git remote set-url origin $CF_RELEASE_GIT_URL
    git fetch -q
  fi

  cd ~/cf-release
  git checkout -q $CF_RELEASE_REVISION

  ./update  >> update.log 2>&1
  if [ $? != 0 ]; then
    echo "Update failed, check ~/cf-release/update.log for details: "
    tail update.log
  fi
}

upload_stemcell() {
  # Download the stemcell if it is not locally
  cd ~
  if [ ! -f $STEMCELL ]; then
    echo "Downloading stemcell $STEMCELL"
    if [ "$STEMCELL_URL" ]; then
      wget $STEMCELL_URL
    else
      time $BOSH_CLI download public stemcell $STEMCELL
    fi
  fi

  # Extract stemcell version and name info
  mkdir -p /tmp/{$STEMCELL}.d
  tar -xzf $STEMCELL -C /tmp/{$STEMCELL}.d stemcell.MF
  stemcell_name=$(cat /tmp/{$STEMCELL}.d/stemcell.MF | awk '/^name:/ { print $2 }')
  stemcell_version=$(cat /tmp/{$STEMCELL}.d/stemcell.MF | awk '/^version:/ { print $2 }' | tr -d "'")

  # Upload stemcell if it is not uploaded
  if bundle exec $SCRIPT_DIR/bosh_list_stemcells.rb | grep -q -e "$stemcell_name/$stemcell_version"; then
    echo "Stemcell $stemcell_name/$stemcell_version already uploaded, skipping"
  else
    time $BOSH_CLI upload stemcell $STEMCELL --skip-if-exists
  fi
}

upload_releases() {
  for r in $BOSH_RELEASES; do
    local name=$(echo $r | cut -f 1 -d ,)
    local version=$(echo $r | cut -f 2 -d ,)
    local url=$(echo $r | cut -f 3 -d ,)
    if bundle exec $SCRIPT_DIR/bosh_list_releases.rb | grep -q "$name/$version"; then
      echo "Release $name version $version already uploaded, skipping"
      continue
    else
      $BOSH_CLI upload release $url 2>&1 | tee /tmp/upload_release.log
      if [ $PIPESTATUS != 0 ] && ! grep -q -e 'Release.*already exists' /tmp/upload_release.log;  then
        return 1
      fi
    fi
  done
}

cf_prepare_deployment() {
  clone_and_update_cf_release
  upload_stemcell
  upload_releases
}

install_dependencies
deploy_and_login_bosh
cf_prepare_deployment
