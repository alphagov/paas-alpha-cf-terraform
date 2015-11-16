#!/bin/sh

templates=$(dirname $0)/templates

infrastructure=$1

shift

if [ "$infrastructure" != "aws" ] && \
    [ "$infrastructure" != "gce" ] ; then
  echo "usage: ./generate_docker_manifest.sh <aws|gce>"
  exit 1
fi

spiff merge \
  $templates/docker/docker-deployment.yml \
  $templates/docker/docker-jobs.yml \
  $templates/docker/docker-properties.yml \
  $templates/docker/docker-broker-services.yml \
  $templates/docker/docker-infrastructure-${infrastructure}.yml \
  $templates/stubs/director-uuid.yml \
  $templates/outputs/terraform-outputs-${infrastructure}.yml \
  $templates/cf-secrets.yml \
