#! /bin/bash

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

cd ~

# Generate manifest
./generate_redis_manifest.sh $TARGET_PLATFORM > ~/redis-manifest.yml

# Deploy redis
$BOSH_CLI deployment ~/redis-manifest.yml
time $BOSH_CLI -n deploy

# Register broker
curl --fail --silent --insecure https://redis.$terraform_output_cf_root_domain > /dev/null || time $BOSH_CLI -n run errand broker-registrar

# Cofigure security
REDIS_IP=$(/usr/local/bin/bosh vms 2>&1 | awk  '$2 ~ /redis\/0/ {print $8}')
echo '[{"protocol":"tcp","destination":"'$REDIS_IP'","ports":"1-65535"}]' > redis-sec-group.json
cf create-security-group redis-security-group redis-sec-group.json
cf bind-staging-security-group redis-security-group
cf bind-running-security-group redis-security-group
