#! /bin/bash

#env GIT_SSL_NO_VERIFY=true git clone https://github.gds/multicloudpaas/credentials ~/.paas-pass
echo "192.168.9.110 github.gds" >> /etc/hosts
mkdir -p ~/.ssh/
chmod 600 ~/.ssh
echo $JENKINS_SSH_KEY > ~/.ssh/id_rsa.pub
echo $JENKINS_PRIVATE_SSH_KEY > ~/.ssh/id_rsa.pub
echo "github.gds,192.168.9.110 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLN3zohMrxpugJsxfy7Js+e75jVAm1xhiHTD7+GUaLMxGbp9oDxxvctS0xY+hvi7PWU/SUnU2AaShZf21HXARXE=" >> ~/.ssh/known_hosts
chmod 400 ~/.ssh/id_rsa.pub
git clone jenkins@git@github.gds:multicloudpaas/credentials.git ~/.paas-pass
for i in ~/.*-pass; do
  [ -e $i/.load.bash ] && . $i/.load.bash
done
DIR=$(dirname $0)
cd $DIR

echo Setting up ssh-agent and cleanup trap
echo $INSECURE_DEPLOYER_SSH_KEY > ~/.ssh/insecure-deployer
chmod 400 ~/.ssh/insecure-deployer
eval $(ssh-agent) && ssh-add ~/.ssh/insecure-deployer
set -e
trap "kill ${SSH_AGENT_PID}" ERR

make aws DEPLOY_ENV=piotr ${EXTRA_OPTIONS}
