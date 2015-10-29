#!/bin/sh

templates=$(dirname $0)/templates

infrastructure=$1

shift

if [ "$infrastructure" != "aws" ] && \
    [ "$infrastructure" != "gce" ] && \
    [ "$infrastructure" != "warden" ] && \
    [ "$infrastructure" != "vsphere" ] ; then
  echo "usage: ./generate_deployment_manifest <aws|warden|vsphere> [stubs...]"
  exit 1
fi

spiff merge \
  $templates/logsearch/logsearch-deployment.yml \
  $templates/logsearch/logsearch-filters.yml \
  $templates/logsearch/logsearch-minimal-jobs.yml \
  $templates/logsearch/logsearch-infrastructure-${infrastructure}.yml \
  $templates/logsearch/stub.yml \
  $templates/stubs/director-uuid.yml \
  $templates/outputs/terraform-outputs-${infrastructure}.yml \
  $templates/cf-secrets.yml \
  "$@"
