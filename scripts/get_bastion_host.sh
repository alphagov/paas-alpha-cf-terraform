#!/bin/sh

if [ -z "$DEPLOY_ENV" -o -z "$1" ]; then
  cat << EOF
Prints the bastion ip from the terraform state, or the hostname if the
terraform state is missing or there is any error reading it.

Usage:
  DEPLOY_ENV=... $0 <gce|aws>
EOF
  exit 0
fi

TARGET_PLATFORM=$1

bastion_ip=
tfstate=$(dirname $0)/../$TARGET_PLATFORM/$DEPLOY_ENV.tfstate
if [ -f "$tfstate" ]; then
  bastion_ip=$(terraform output -state=$tfstate bastion_ip 2>/dev/null)
else
  echo "Warning: No terraform state file for DEPLOY_ENV=$DEPLOY_ENV: $tfstate" 1>&2
fi

if [ "$bastion_ip" ]; then
  result=$bastion_ip
else
  if [ "$TARGET_PLATFORM" == "aws" ]; then
    result="$DEPLOY_ENV-bastion.cf.paas.alphagov.co.uk"
  elif [ "$TARGET_PLATFORM" == "gce" ]; then
    result="$DEPLOY_ENV-bastion.cf2.paas.alphagov.co.uk"
  else
    echo "Error: $0: Unknown target platform: $TARGET_PLATFORM" 1>&2
    exit 1
  fi
  echo "Warning: $0: Failing retrieving bastion ip from terraform, failover to DNS: $result" 1>&2
fi

echo $result
