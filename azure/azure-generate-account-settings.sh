#!/bin/bash

set -e

if [ $# -lt 1 ]; then
	cat <<EOF
Usage:
	$0 <deploy_env>

Initialises your account with the required account objects for BOSH on azure,
and creates a generated.azure_settings.sh file with all the environment
variables needed for terraform.

EOF
	exit 1
fi
deploy_env=$1; shift

if [ -s generated.azure_account_settings.sh ]; then
  echo "File 'generated.azure_account_settings.sh' already exists. Skipping initialisation."
  exit 0
fi

azure_subscription_id=$(azure account list | cat | sed -n 4p | awk '{ print $3 }')
azure_tenant_id=$(azure account list | cat | sed -n 4p | awk '{ print $4 }')

azure_client_secret=$(openssl rand -base64 16)

SERVICE_PASSWORD=$azure_client_secret ./azure-create-service-principal.sh $deploy_env $azure_subscription_id

(
echo "# Load the file 'source ./generated.azure_account_settings.sh' to load these variables: "
echo "export TF_VAR_azure_subscription_id=$azure_subscription_id"
echo "export TF_VAR_azure_tenant_id=$azure_tenant_id"
echo "export TF_VAR_azure_client_secret='$azure_client_secret'"
echo "export TF_VAR_azure_client_id=$(< generated.application_id)"
) | tee generated.azure_account_settings.sh


