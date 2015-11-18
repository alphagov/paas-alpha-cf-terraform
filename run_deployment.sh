#! /bin/bash

git -c http.sslVerify=false clone https://github.gds/multicloudpaas/credentials ~/.paas-pass
DIR=$(dirname $0)
cd $DIR
echo $DIR


echo Setting up ssh-agent and cleanup trap
echo $SSH_KEY
echo $SSH_KEY > ~/.ssh/insecure-deployer
chmod 400 ~/.ssh/insecure-deployer
eval $(ssh-agent) && ssh-add ~/.ssh/insecure-deployer
set -e
trap "kill ${SSH_AGENT_PID}" ERR

make aws DEPLOY_ENV=piotr ${EXTRA_OPTIONS}
