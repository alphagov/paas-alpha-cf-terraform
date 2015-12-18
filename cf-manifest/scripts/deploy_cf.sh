#!/bin/bash

set -e # fail on error

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

# Include the terraform output variables
. $SCRIPT_DIR/../outputs/terraform-outputs.sh

export BUNDLE_GEMFILE=$SCRIPT_DIR/Gemfile
BOSH_CLI="bundle exec bosh"

# Other config
export PATH=$PATH:/usr/local/bin

# Merge the UUID and secrets into the prebuilt manifest
cf_compile_manifest() {
  # Output the director uuid to be populated by spiff
  echo -e "---\ndirector_uuid: $($BOSH_CLI status --uuid)" > ~/outputs/director-uuid.yml
  ./scripts/generate_cf_manifest.sh > ~/outputs/cf-manifest.yml
}

cf_deploy() {
  $BOSH_CLI deployment ~/outputs/cf-manifest.yml
  time $BOSH_CLI -n deploy
}

cf_compile_manifest
cf_deploy
