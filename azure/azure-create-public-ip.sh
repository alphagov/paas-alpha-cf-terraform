#!/bin/bash

set -e

if [ $# -lt 2 ]; then
	cat <<EOF
Usage:
	$0 <resource_group_name> <ip_name>

Creates a public IP
EOF
	exit 1
fi

resource_group_name=$1; shift
ip_name=$1; shift

azure config mode arm
azure resource create \
     ${resource_group_name} \
     ${ip_name} \
     Microsoft.Network/publicIPAddresses \
     "West Europe" 2015-05-01-preview \
     -p "{\"publicIPAllocationMethod\":\"static\"}"

sleep 5

azure resource show \
     ${resource_group_name} \
     ${ip_name} \
     Microsoft.Network/publicIPAddresses \
     2015-05-01-preview | awk '/Property ipAddress/ {print $4}' | tee generated.${ip_name}

echo "Created IP $(<generated.${ip_name}), stored in generated.${ip_name}"
