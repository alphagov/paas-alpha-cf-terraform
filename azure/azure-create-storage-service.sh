#!/bin/bash

if [ $# -lt 3 ]; then
	cat <<EOF
Usage:
	$0 <resource group name> <storage_account_name> <account_key_file>

Will create a storage service name and store the credencials on the given file
so they can be consumed by terraform
EOF
	exit 1
fi

resource_group_name=$1; shift
storage_account_name=$1; shift
account_key_file=$1; shift

set -x

azure config mode arm # Change azure client mode, needed to run `azure resource create`

echo "Check if the account already exists"
echo $resource_group_name | azure storage account show  $storage_account_name
RET=$?

if [ $RET != 0 ]; then
	echo "Creating account"
	azure resource create $resource_group_name $storage_account_name \
		Microsoft.Storage/storageAccounts "West Europe" \
		2015-05-01-preview \
		-p "{\"accountType\":\"Standard_LRS\"}"
	# Horrible workaround. It fails once with Error:null
	if [ $? != 0 ] && grep 'Error: null' ~/.azure/azure.err; then
		echo "Warning: Ignoring 'Error: null' error... The account gets created anyway"
	else
		exit 1
	fi
else
	echo "Warning: $storage_account_name account already exists in  $storage_service_name. Not creating it."
fi

sleep 30
echo "Retrieving the account key from the command line azure client"
echo $resource_group_name | \
	azure storage account keys list $storage_account_name --json > ${account_key_file}.json

sed -n 's/.*"key1":.*"\(.*\)".*/\1/p' <  ${account_key_file}.json > $account_key_file || exit 1

echo "Account $storage_account_name created, key in file $account_key_file."

