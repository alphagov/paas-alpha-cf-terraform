#!/bin/bash

set -e

manifest_generation=${DIEGO_RELEASE_PATH}/manifest-generation
templates_dir=$(cd $(dirname $0); pwd)/templates
deployments=/tmp/deployments
tmpdir=/tmp/diego

mkdir -p $tmpdir

spiff merge \
  ${manifest_generation}/config-from-cf.yml \
  ${manifest_generation}/config-from-cf-internal.yml \
  ${deployments}/cf-manifest.yml \
  > ${tmpdir}/config-from-cf.yml

spiff merge \
  ${manifest_generation}/diego.yml \
  ${templates_dir}/diego/colocated-instance-count-overrides.yml \
  ${templates_dir}/diego/property-overrides.yml \
  ${templates_dir}/diego/iaas-settings.yml \
  ${tmpdir}/config-from-cf.yml \
  ${templates_dir}/outputs/terraform-outputs-aws.yml \
  > ${tmpdir}/diego.yml

spiff merge \
  ${manifest_generation}/misc-templates/bosh.yml \
  ${templates_dir}/stubs/director-uuid.yml \
  ${tmpdir}/diego.yml
