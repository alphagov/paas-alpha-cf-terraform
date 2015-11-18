#! /bin/bash

export TF_VAR_AWS_ACCESS_KEY_ID=$1
export TF_VAR_AWS_SECRET_ACCESS_KEY=$2

DIR=$(dirname $0)
cd $DIR

#make aws DEPLOY_ENV=piotr
env
#!/bin/bash

echo Set-up ssh keys and credentials

echo Setting up ssh-agent and cleanup trap
echo $SSH_KEY > ~/.ssh/insecure-deployer
chmod 400 ~/.ssh/insecure-deployer
eval $(ssh-agent) && ssh-add ~/.ssh/insecure-deployer
set -e
trap "kill ${SSH_AGENT_PID}" ERR

make aws DEPLOY_ENV=${DEPLOY_ENV} ${EXTRA_OPTIONS}
