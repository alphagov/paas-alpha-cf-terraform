#!/bin/bash
spruce merge \
  deployments/bosh/bosh-template.yml \
  deployments/bosh/bosh-manifest.yml \
  outputs/terraform-outputs.yml \
  outputs/bosh-secrets.yml \
  "$@"
