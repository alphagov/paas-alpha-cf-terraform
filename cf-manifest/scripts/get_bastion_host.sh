#!/bin/bash

bastion_ip=
tfstate=$(dirname $0)/../terraform/$DEPLOY_ENV.tfstate
if [ -f "$tfstate" ]; then
  bastion_ip=$(terraform output -state=$tfstate bastion_ip 2>/dev/null)
else
  echo "Warning: No terraform state file for DEPLOY_ENV=$DEPLOY_ENV: $tfstate" 1>&2
fi

if [ "$bastion_ip" ]; then
  result=$bastion_ip
else
  result="$DEPLOY_ENV-bastion.cf.paas.alphagov.co.uk"
  echo "Warning: $0: Failing retrieving bastion ip from terraform, failover to DNS: $result" 1>&2
fi

echo $result
