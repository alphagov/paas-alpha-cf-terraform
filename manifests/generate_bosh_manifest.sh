#!/bin/bash

infrastructure=$1; shift

templates=$(dirname $0)/templates

case $infrastructure in
  aws|warden)
    ;;
  gce)
    ;;
  *)
    echo "usage: ./generate_deployment_manifest <aws|warden|gce> [stubs...]"
    exit 1
    ;;
esac

spiff merge \
  $templates/bosh/bosh-template.yml \
  $templates/${infrastructure}/bosh/*.yml \
  $templates/outputs/terraform-outputs-${infrastructure}.yml \
  "$@"
