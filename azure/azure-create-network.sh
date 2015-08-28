#!/bin/sh

if [ $# -lt 5 ]; then
	cat <<EOF
Usage:
	$0 <resource_group_name> <network_name> <network_cidr> <subnet_name> <subnet_cidr>

Creates network and subnet for cloudfoundry

Can be deleted with: "azure network vnet delete env-cf-hosted-service env-cf-network"
EOF
	exit 1
fi

resource_group_name=$1; shift
network_name=$1; shift
network_cidr=$1; shift
subnet_name=$1; shift
subnet_cidr=$1; shift

azure config mode arm
azure resource create \
	${resource_group_name} \
	${network_name} \
	Microsoft.Network/virtualNetworks \
	'West Europe' 2015-05-01-preview \
	-p "{\"addressSpace\": {\"addressPrefixes\": [\"${network_cidr}\"]},\"subnets\": [{\"name\": \"${subnet_name}\",\"properties\" : { \"addressPrefix\": \"${subnet_cidr}\"}}]}"

