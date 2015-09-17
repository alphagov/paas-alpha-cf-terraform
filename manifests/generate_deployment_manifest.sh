#!/bin/bash

if [[ -z "$CF_RELEASE_PATH" ]]; then
  echo "Must set \$CF_RELEASE_PATH with the cf-release repository path"
  exit 1
fi

infrastructure=$1; shift

if [ "$infrastructure" != "aws" ] && \
    [ "$infrastructure" != "openstack" ] && \
    [ "$infrastructure" != "warden" ] && \
    [ "$infrastructure" != "vsphere" ] ; then
  echo "usage: ./generate_deployment_manifest <aws|openstack|warden|vsphere> [stubs...]"
  exit 1
fi

templates=$(dirname $0)/templates

spiff merge \
  $CF_RELEASE_PATH/templates/cf-deployment.yml \
  $templates/deployments/*.yml \
  $CF_RELEASE_PATH/templates/cf-resource-pools.yml \
  $CF_RELEASE_PATH/templates/cf-jobs.yml \
  $CF_RELEASE_PATH/templates/cf-properties.yml \
  $CF_RELEASE_PATH/templates/cf-lamb.yml \
  $CF_RELEASE_PATH/templates/cf-infrastructure-${infrastructure}.yml \
  $CF_RELEASE_PATH/templates/cf-minimal-dev.yml \
  $templates/stubs-${infrastructure}/*.yml \
  $templates/stubs/*.yml \
  $templates/outputs/terraform-outputs-${infrastructure}.yml \
  "$@"

