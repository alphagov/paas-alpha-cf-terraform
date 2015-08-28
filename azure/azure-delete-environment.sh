#!/bin/sh

if [ $# -lt 1 ]; then
	cat <<EOF
Usage:
	$0 <deploy_env>

Deletes all the objects in the given environment.
EOF
	exit 1
fi

deploy_env=$1; shift
resource_group=${deploy_env}-cf-hosted-service

set -e

echo "Resources for this group:"
azure resource list | grep -- ${resource_group} | awk '{ print $3, $4, $5 }'

echo "===================================================================="
echo "Deleting VMs"

for vm in $(azure resource list | grep -- ${resource_group} | grep virtualMachines | awk '{print $3}'); do
	echo "Deleting VM $vm"
	azure vm delete $resource_group $vm -q
done

echo "===================================================================="
echo "Deleting Load Balancers"

for lb in $(azure resource list | grep -- ${resource_group} | grep loadBalancers | awk '{print $3}'); do
	echo "Deleting Load Balancer $lb"
	azure network lb delete $resource_group $lb -q
done

echo "===================================================================="
echo "Deleting Public IPs"

for ip in $(azure resource list | grep -- ${resource_group} | grep publicIPAddresses | awk '{print $3}'); do
	echo "Deleting IP $ip"
	azure network public-ip delete $resource_group $ip  -q
done

echo "===================================================================="
echo "Deleting NICs"

for nic in $(azure resource list | grep -- ${resource_group} | grep networkInterfaces | awk '{print $3}'); do
	echo "Deleting NIC $nic"
	azure network nic delete $resource_group $nic  -q
done

echo "===================================================================="
echo "Deleting Networks"

for vnet in $(azure resource list | grep -- ${resource_group} | grep virtualNetworks | awk '{print $3}'); do
	echo "Deleting Network $vnet"
	azure network vnet delete $resource_group $vnet  -q
done

echo "===================================================================="
echo "Deleting Storage"

for storage_account in $(azure resource list | grep -- ${resource_group} | grep storageAccounts | awk '{print $3}'); do
	echo "Deleting Storage $storage_account"
	export AZURE_STORAGE_CONNECTION_STRING=$(echo $resource_group | azure storage account connectionstring show $storage_account | awk '/connectionstring:/ {print $3}')
	for container in $(azure storage container  list | grep data | sed 1,2d | awk '{print $2}'); do
		echo "Deleting container $container"
		azure storage container delete $container -q
	done
	echo "Deleting Storage account $storage_account"
	azure storage account delete -g $resource_group $storage_account  -q
done

echo "===================================================================="
echo "Deleting Resource Group"
if ! azure group list | grep -q $resource_group; then
	echo "Group not found"
else
	azure group delete $resource_group -q
fi

