#!/bin/bash

set -e

SCRIPT_NAME=$0

usage() {
  cat <<EOF
DIEGO_RELEASE_PATH=... [CF_MANIFEST_FILE=~/cf-manifest.yml] $SCRIPT_NAME <aws|gce>
EOF
}

if [ -z "${DIEGO_RELEASE_PATH}" ]; then
  echo "You must pass DIEGO_RELEASE_PATH environment variable"
  exit 1
fi

CF_MANIFEST_FILE=${CF_MANIFEST_FILE:-~/cf-manifest.yml}
if [ ! -f "$CF_MANIFEST_FILE" ]; then
  echo "Cannot find the cf-manifest.tml file. Pass it with CF_MANIFEST_FILE"
  exit 1
fi

manifest_generation=${DIEGO_RELEASE_PATH}/manifest-generation
templates_dir=$(cd $(dirname $0); pwd)/templates
deployments=/tmp/deployments
tmpdir=/tmp/diego

mkdir -p $tmpdir

# Extract the cf config.
spiff merge \
  ${manifest_generation}/config-from-cf.yml \
  ${manifest_generation}/config-from-cf-internal.yml \
  $CF_MANIFEST_FILE \
  > ${tmpdir}/config-from-cf.yml

spiff merge \
  ${manifest_generation}/misc-templates/bosh.yml \
  ${templates_dir}/stubs/director-uuid.yml \
  ${templates_dir}/diego/property-and-job-addons.yml \
  ${manifest_generation}/diego.yml \
  ${templates_dir}/diego/colocated-instance-count-overrides.yml \
  ${templates_dir}/diego/property-overrides.yml \
  ${templates_dir}/diego/iaas-settings.yml \
  ${tmpdir}/config-from-cf.yml \
  ${templates_dir}/outputs/terraform-outputs-aws.yml \


