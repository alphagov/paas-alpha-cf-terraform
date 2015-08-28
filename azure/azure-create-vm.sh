#!/bin/bash

if [ $# -lt 1 ]; then
	cat <<EOF
Usage:
	$0 <resource_group> <vm_name> <storage_account_name> <ssh_public_key> <subscription_id> <network_name> <ip>

Creates a new VM in a specified resource group."
EOF
	exit 1
fi

resource_group_name=$1; shift
vm_name=$1; shift
storage_account_name=$1; shift
ssh_public_key=$1; shift
subscription_id=$1; shift
network_name=$1; shift
ip=$1; shift

echo "Check if the VM already exists"
azure vm list --resource-group $resource_group_name | cat | grep $vm_name -q
RET=$?

if [ $RET != 0 ]; then
	echo "Creating VM"
	azure config mode arm
  azure vm create --resource-group $resource_group_name \
    --name $vm_name \
    -l "West Europe" \
    --image-urn Canonical:UbuntuServer:14.04.3-LTS:14.04.201508050 \
    --vm-size Basic_A3 \
    --storage-account-name $storage_account_name \
    --os-type Linux \
    --ssh-publickey-file $ssh_public_key \
    -u ubuntu -p Password1* \
    --nic-id /subscriptions/$subscription_id/resourceGroups/$resource_group_name/providers/Microsoft.Network/networkInterfaces/$network_name
else
	echo "Warning: $vm_name VM already exists in $resource_group_name. Not creating it."
fi
