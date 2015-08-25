#!/bin/bash

set -e

SCRIPT_NAME=$0

usage() {
	cat <<EOF
Usage:
	$SCRIPT_NAME <azure_hostname> <endpoint_name> <base_priority> <permit|deny> <comma_list_cidr>

Creates the given ACL rules in azure using 'azure-cli'. It implements logic to split
the cidr by comma and add multiple rules.

Note: base priority will be incremented as many CIDR addresses are given.

EOF
}

if [  "$#" -lt 5 ]; then
	usage
	exit 1
fi

host=$1; shift
endpoint=$1; shift
priority=$1; shift
action=$1; shift
list_cidr=$1; shift

IFS=','
count=0
for cidr in $list_cidr; do
	echo "Executing 'azure vm endpoint acl-rule create $host $endpoint $((priority+count)) $action $cidr'"
	azure vm endpoint acl-rule create $host $endpoint $((priority+count)) $action $cidr
	count=$((count + 1))
done

azure vm endpoint acl-rule list $host $endpoint
