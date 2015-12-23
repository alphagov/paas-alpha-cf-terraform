#!/bin/bash 

set -e # fail on error

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

get_bosh_secret() { ${SCRIPT_DIR}/val_from_yaml.rb templates/bosh-secrets.yml $1; }

STEMCELL=light-bosh-stemcell-3104-aws-xen-hvm-ubuntu-trusty-go_agent.tgz
TARGET_PLATFORM=$1
TARGET_PLATFORM="aws"

# Include the terraform output variables
. $SCRIPT_DIR/terraform-outputs-${TARGET_PLATFORM}.sh

BOSH_ADMIN_USER=${BOSH_ADMIN_USER:-admin}
BOSH_IP=${BOSH_IP:-$terraform_output_bosh_ip}
BOSH_PORT=${BOSH_PORT:-25555}

# Git cf-release to clone
CF_RELEASE=225
# Releases to upload
BOSH_RELEASES="
cf,$CF_RELEASE,https://bosh.io/d/github.com/cloudfoundry/cf-release?v=$CF_RELEASE
nginx,2,https://s3.amazonaws.com/nginx-release/nginx-2.tgz"
# Dependencies versions
BOSH_INIT_VERSION=0.0.72
BOSH_INIT_URL=https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${BOSH_INIT_VERSION}-linux-amd64
SPRUCE_VERSION=v0.13.0
SPRUCE_URL=https://github.com/geofffranks/spruce/releases/download/${SPRUCE_VERSION}/spruce_0.13.0_linux_amd64.tar.gz
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

echo "Installing binaries: spiff"

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
    cd ~ && ./generate_bosh_manifest.sh $TARGET_PLATFORM > $BOSH_MANIFEST
    export BOSH_INIT_LOG_LEVEL=debug
    export BOSH_INIT_LOG_PATH=/tmp/bosh_init.log
    time bosh-init deploy $BOSH_MANIFEST
  fi

  if ! bosh_check_and_login; then
    echo "Failed to contact BOSH node $BOSH_IP:$BOSH_PORT after provisioning"
    return 1
  fi

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
    local action=$(echo $r | cut -f 4 -d ,)
    local directory=$(echo $r | awk -F"/" '{print $NF}' | cut -d"." -f 1)

    if bundle exec $SCRIPT_DIR/bosh_list_releases.rb | grep -q "$name/$version"; then
      echo "Release $name version $version already uploaded, skipping"
      continue
    else
      if [[ ${action} == "create" ]] ; then
         git_clone ${url} ${version}
         if [[ $(grep -R ${version} ~/${directory}/dev_releases/) == "" ]]; then
           $BOSH_CLI create release --name ${name} --version ${version}
         fi
         url=""
      fi

      $BOSH_CLI upload release $url 2>&1 | tee /tmp/upload_release.log
      if [ $PIPESTATUS != 0 ] && ! grep -q -e 'Release.*already exists' /tmp/upload_release.log;  then
        return 1
      fi
    fi
  done
}
}

install_dependencies
deploy_and_login_bosh
upload_stemcell
upload_releases
