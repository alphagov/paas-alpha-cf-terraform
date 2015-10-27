#!/bin/bash

set -e # fail on error

SCRIPT_DIR=$(cd $(dirname $0) && pwd)


# Read the platform configuration
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

export BUNDLE_GEMFILE=$SCRIPT_DIR/Gemfile
BOSH_CLI="bundle exec bosh"

# Other config
export PATH=$PATH:/usr/local/bin

# Include the terraform output variables
. $SCRIPT_DIR/terraform-outputs-${TARGET_PLATFORM}.sh

logsearch_compile_manifest() {
  # Use spiff to generate logsearch deployment manifest
  cd ~

  # Generate the manifest
  ./generate_logsearch_manifest.sh $TARGET_PLATFORM > ~/logsearch-manifest.yml
}

logsearch_deploy() {
  $BOSH_CLI deployment ~/logsearch-manifest.yml
  time $BOSH_CLI -n deploy
  curl --silent --insecure https://logs.$terraform_output_cf_root_domain > /dev/null || time $BOSH_CLI -n run errand push-kibana
}


logsearch_compile_manifest
logsearch_deploy
