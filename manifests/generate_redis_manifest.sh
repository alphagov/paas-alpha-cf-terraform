#!/bin/sh

templates=$(dirname $0)/templates

infrastructure=$1

shift

if [ "$infrastructure" != "aws" ] && \
    [ "$infrastructure" != "gce" ] ; then
  echo "usage: ./generate_deployment_manifest <aws|gce> [stubs...]"
  exit 1
fi

spiff merge \
  $templates/redis/redis-deployment.yml \
  $templates/redis/redis-jobs.yml \
  $templates/redis/redis-infrastructure-${infrastructure}.yml \
  $templates/redis/stub.yml \
  $templates/stubs/director-uuid.yml \
  $templates/outputs/terraform-outputs-${infrastructure}.yml \
  $templates/cf-secrets.yml \
