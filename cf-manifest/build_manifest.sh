#!/bin/sh

set -e
cd $(dirname $0)

spruce merge \
  --prune terraform_outputs --prune secrets \
  deployments/*.yml \
  deployments/aws/*.yml \
  "$@"
