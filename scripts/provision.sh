#!/bin/bash

set -e # fail on error

# Platform
# Read the platform configuration
TARGET_PLATFORM=$1
case $TARGET_PLATFORM in
  aws)
    STEMCELL=light-bosh-stemcell-3069-aws-xen-hvm-ubuntu-trusty-go_agent.tgz
    ;;
  gce)
    STEMCELL=light-bosh-stemcell-2968-google-kvm-ubuntu-trusty-go_agent.tgz
    STEMCELL_URL=http://storage.googleapis.com/bosh-stemcells/$STEMCELL
    BOSH_IP=104.155.37.66
    ;;
  *)
    echo "Must specify the target platform: gce|aws"
    exit 1
    ;;
esac

# Convert the yaml outputs file to a list of environment variables:
#
#   terraform_output_bastion_ip=104.155.62.123
#   terraform_output_bosh_ip=104.155.37.66
#
# etc...
eval $(
  cat templates/outputs/terraform-outputs-${TARGET_PLATFORM}.yml | \
    sed -n 's/ *\(.*\): *\(..*\)$/terraform_output_\1=\2/p'
)

BOSH_ADMIN_USER=${BOSH_ADMIN_USER:-admin}
BOSH_ADMIN_PASS=${BOSH_ADMIN_USER:-admin}
BOSH_IP=${BOSH_IP:-$terraform_output_bosh_ip}
BOSH_PORT=${BOSH_PORT:-25555}

# Git cf-release to clone
CF_RELEASE=215
CF_RELEASE_GIT_URL=https://github.com/alphagov/cf-release.git
CF_RELEASE_REVISION=cf_jobs_without_static_ips_dependencies_v215

# Releases to upload
BOSH_RELEASES="
cf,215,https://bosh.io/d/github.com/cloudfoundry/cf-release?v=$CF_RELEASE
elasticsearch,0.1.0,https://github.com/hybris/elasticsearch-boshrelease/releases/download/v0.1.0/elasticsearch-0.1.0.tgz
"

# Constants
BOSH_MANIFEST=~/bosh-manifest.yml

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

# Bosh
bosh_login() {
  echo "Login to bosh $BOSH_IP:$BOSH_PORT"
  echo -e "${BOSH_ADMIN_USER}\n${BOSH_ADMIN_PASS}" | \
    bosh target $BOSH_IP:$BOSH_PORT
}

bosh_check_and_login() {
  # Try to connect to the TCP port with 1s timeout
  nc -z -w 1 $BOSH_IP $BOSH_PORT || return 1

  if [ ! -s ~/.bosh_config ]; then
    bosh_login || return 1
  fi

  # do a bosh status to check health
  bosh status > /dev/null || return 1
}

deploy_and_login_bosh() {

  if bosh_check_and_login; then
    echo "MicroBOSH up and running, not updating. Run 'bosh-init deploy $BOSH_MANIFEST' to rerun deploy manually."
  else
    echo "MicroBOSH node in $BOSH_IP:$BOSH_PORT is not configured or responding. Deploying it with bosh-init."
    export BOSH_INIT_LOG_LEVEL=debug
    export BOSH_INIT_LOG_PATH=bosh_init.log
    time bosh-init deploy $BOSH_MANIFEST
  fi
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
      time bosh download public stemcell $STEMCELL
    fi
  fi

  # Extract stemcell version and name info
  mkdir -p /tmp/{$STEMCELL}.d
  tar -xzf $STEMCELL -C /tmp/{$STEMCELL}.d stemcell.MF
  stemcell_name=$(cat /tmp/{$STEMCELL}.d/stemcell.MF | awk '/^name:/ { print $2 }')
  stemcell_version=$(cat /tmp/{$STEMCELL}.d/stemcell.MF | awk '/^version:/ { print $2 }' | tr -d "'")

  # Upload stemcell if it is not uploaded
  if ! bosh stemcells 2>/dev/null | grep -q -e "$stemcell_name .* $stemcell_version"; then
    time bosh upload stemcell $STEMCELL --skip-if-exists
  fi
}

upload_releases() {
  for r in $BOSH_RELEASES; do
    local name=$(echo $r | cut -f 1 -d ,)
    local version=$(echo $r | cut -f 2 -d ,)
    local url=$(echo $r | cut -f 3 -d ,)
    # TODO, Detect if the release is already uploaded
    #
    # if bosh releases 2>/dev/null | grep -q " $name .* $version "; then
    #  echo "Release $name version $version already uploaded, skipping"
    #  continue
    #else
    #  bosh upload release $url
    #fi
    bosh upload release $url 2>&1 | tee /tmp/upload_release.log
    if [ $PIPESTATUS != 0 ]; then
      if ! grep -q -e 'Release.*already exists' /tmp/upload_release.log;  then
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

cf_compile_manifest() {
  # Use spiff to generate CF deployment manifest
  cd ~

  # Output the director uuid to be populated by spiff
  echo -e "---\ndirector_uuid: $(bosh status --uuid)" > templates/stubs/director-uuid.yml

  # Generate the manifest
  CF_RELEASE_PATH=~/cf-release/ ./generate_deployment_manifest.sh $TARGET_PLATFORM > ~/cf-manifest.yml
}

cf_deploy() {
  bosh deployment ~/cf-manifest.yml
  time bosh -n deploy
}

cf_post_deploy() {
  # Deploy psql broker
  time bash ~/deploy_psql_broker.sh admin fakepassword
}

install_dependencies
deploy_and_login_bosh
cf_prepare_deployment
cf_compile_manifest
cf_deploy
cf_post_deploy

