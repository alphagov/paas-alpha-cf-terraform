#!/bin/bash

if [ $# -lt 1 ]; then
	cat <<EOF
Usage:
	$0 <deploy_env> <azure_subscription_id>

Setups the application and service pricipal for bosh for the given environment.
Granting the role of Contributor.

Password must be pass as a environment variable: \$SERVICE_PASSWORD
EOF
	exit 1
fi

deploy_env=$1; shift
azure_subscription_id=$1; shift

azure config mode arm

echo "Creating application resource in the active directory:"
azure ad app create \
    --name "Service Principal for BOSH - Environment: $deploy_env" \
    --password "$SERVICE_PASSWORD" \
    --home-page "http://BOSHAzureCPI-$deploy_env" \
	--identifier-uris "http://BOSHAzureCPI-$deploy_env" | \
		tee generated.active_directory_app_${deploy_env}_info.txt

if [ ${PIPESTATUS[0]} != 0 ]; then
    # Skip if it already exists
    if grep -q 'Another object with the same value for property identifierUris already exists' ~/.azure/azure.err; then
    	echo "The app already exists, skipping"
    else
	echo "Failed"
	exit 1
    fi
fi

application_id=$(cat generated.active_directory_app_${deploy_env}_info.txt | sed -n 's/.*Application Id: *\(.*\)$/\1/p')
echo $application_id > generated.application_id
echo "Created application 'http://BOSHAzureCPI-$deploy_env' with ID (this is your client_id): $application_id"

echo "Creating Service principal for the created application $application_id"
azure ad sp create $application_id || exit 1

echo "Waiting for the orcs in Azure to manually create the resources we have just requested..."
sleep 30

echo "Assigning 'Contributor' role to application 'http://BOSHAzureCPI-$deploy_env'"
azure role assignment create \
	--spn "http://BOSHAzureCPI-$deploy_env" \
	-o "Contributor" \
	--subscription $azure_subscription_id || exit 1


