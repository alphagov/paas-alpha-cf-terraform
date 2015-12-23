#!/bin/sh

set -e
set -x
#cd $(dirname $0)

terraform_outputs=${TERRAFORM_OUTPUTS:-"templates/outputs/terraform-outputs-aws.yml"}
secrets=${SECRETS:-"templates/cf-secrets.yml"}
ssl_certs=${SSL_CERTS:-"templates/cf-ssl-certificates.yml"}
director_uuid=${DIRECTOR_UUID:-"templates/director-uuid.yml"}

spruce merge \
  --prune meta --prune lamb_meta \
  --prune terraform_outputs \
  --prune secrets \
  deployments/*.yml \
  deployments/aws/*.yml \
  ${terraform_outputs} \
  ${secrets} \
  ${ssl_certs} \
  ${director_uuid}
