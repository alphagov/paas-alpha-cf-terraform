#!/bin/sh

set -e
cd $(dirname $0)

terraform_output=${TERRAFORM_OUTPUT:-"outputs/terraform-outputs.yml"}

spruce merge \
  --prune terraform_outputs --prune secrets \
  deployments/*.yml \
  deployments/aws/*.yml \
  ${terraform_output}
