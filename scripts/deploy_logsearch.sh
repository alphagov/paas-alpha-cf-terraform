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

#
# Retrieve the elasticsearch IP from the bosh output.
#
# Currently the errand that deploys kibana-for-cloudfoundry tries to setup a
# security-group on CF based to allow access to elasticsearch based on the IP
# defined in the manifest. There is no way to specify an IP range and
# DNS aliases are not valid in this case.
#
# This is an issue, as GCE does not have static IPs, but the VMs get IPs
# dynamically allocated.
#
# The solution requires either do a pull request or deploy kibana out of the
# errand, but as a **sort term** solution we will workaround this by:
#
#  1. Deploy logsearch (Elasticsearch+Lostash as usual)
#  2. Query bosh to get the allocated IP.
#  3. Generate a spiff stub with the IP for eleasticsearch.
#  4. Run the errand with the new config.
#
gen_elasticsearch_ip_stub() {
  elasticsearch_ip=$(bosh vms 2> /dev/null | grep logsearch_minimal | awk '{print $8}')
  if [ ! -z "$elasticsearch_ip" ]; then
  cat <<EOF
---
properties:
  elasticsearch:
    admin_ip: $elasticsearch_ip
EOF
  else
    echo "---"
  fi
}

logsearch_compile_manifest() {
  # Use spiff to generate logsearch deployment manifest
  cd ~

  # Get ES ip in a new stub
  additional_stubs=""
  if [ "$TARGET_PLATFORM" == gce ]; then
    gen_elasticsearch_ip_stub > ~/templates/outputs/elasticsearch_ip.yml
    additional_stubs=~/templates/outputs/elasticsearch_ip.yml
  fi

  ./generate_logsearch_manifest.sh $TARGET_PLATFORM $additional_stubs > ~/logsearch-manifest.yml
}

logsearch_deploy() {
  $BOSH_CLI deployment ~/logsearch-manifest.yml
  time $BOSH_CLI -n deploy
}

kibana_deploy() {
  curl --fail --silent --insecure \
    https://logs.$terraform_output_cf_root_domain > /dev/null || \
      time $BOSH_CLI -n run errand push-kibana
}

logsearch_compile_manifest
logsearch_deploy

# On GCE we need to recompile and push the manifest to get the ES ip (see above)
if [ "$TARGET_PLATFORM" == gce ]; then
  logsearch_compile_manifest
  logsearch_deploy
fi
kibana_deploy

