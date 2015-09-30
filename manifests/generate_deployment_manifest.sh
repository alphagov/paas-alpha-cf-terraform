#!/bin/bash

if [[ -z "$CF_RELEASE_PATH" ]]; then
  echo "Must set \$CF_RELEASE_PATH with the cf-release repository path"
  exit 1
fi

infrastructure=$1; shift

templates=$(dirname $0)/templates

case $infrastructure in
  aws|warden)
    infrastructure_template=$CF_RELEASE_PATH/templates/cf-infrastructure-${infrastructure}.yml
    ;;
  gce)
    infrastructure_template=$templates/${infrastructure}/cf-infrastructure-${infrastructure}.yml
    ;;
  *)
    echo "usage: ./generate_deployment_manifest <aws|warden|gce> [stubs...]"
    exit 1
    ;;
esac

spiff merge \
  $CF_RELEASE_PATH/templates/cf-deployment.yml \
  $templates/deployments/*.yml \
  $CF_RELEASE_PATH/templates/cf-resource-pools.yml \
  $CF_RELEASE_PATH/templates/cf-jobs.yml \
  $CF_RELEASE_PATH/templates/cf-properties.yml \
  $CF_RELEASE_PATH/templates/cf-lamb.yml \
  $infrastructure_template \
  $templates/${infrastructure}/cf-pool-instances.yml \
  $CF_RELEASE_PATH/templates/cf-minimal-dev.yml \
  $templates/${infrastructure}/stubs/*.yml \
  $templates/stubs/*.yml \
  $templates/outputs/terraform-outputs-${infrastructure}.yml \
  "$@"
