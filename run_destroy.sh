#! /bin/bash

echo "192.168.9.110 github.gds" >> /etc/hosts
mkdir -p ~/.ssh/ ~/.gnupg
chmod 600 ~/.ssh ~/.gnupg
echo "$JENKINS_SSH_KEY" > ~/.ssh/id_rsa.pub
echo "$JENKINS_PRIVATE_SSH_KEY" > ~/.ssh/id_rsa
echo "$INSECURE_DEPLOYER_SSH_KEY" > ~/.ssh/insecure-deployer.pub
echo "$INSECURE_DEPLOYER_PRIVATE_SSH_KEY" > ~/.ssh/insecure-deployer
echo "$JENKINS_GPG_SECURE_KEY" > ~/.gnupg/multicloud-deploy.key
gpg --batch --yes --allow-secret-key-import --import ~/.gnupg/multicloud-deploy.key
echo "github.gds,192.168.9.110 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLN3zohMrxpugJsxfy7Js+e75jVAm1xhiHTD7+GUaLMxGbp9oDxxvctS0xY+hvi7PWU/SUnU2AaShZf21HXARXE=" >> ~/.ssh/known_hosts
chmod 400 ~/.ssh/id_rsa.pub ~/.ssh/id_rsa ~/.ssh/insecure-deployer.pub ~/.ssh/insecure-deployer
git clone git@github.gds:multicloudpaas/credentials.git ~/.paas-pass
for i in ~/.*-pass; do
  [ -e $i/.load.bash ] && . $i/.load.bash
done
#ln -s ./state-file/piotr.tfstate cf-terraform/aws/piotr.tfstate
DIR=$(dirname $0)
cd $DIR

echo Setting up ssh-agent and cleanup trap
eval $(ssh-agent) && ssh-add ~/.ssh/insecure-deployer
mkdir -p aws/ssh
cp ~/.ssh/* aws/ssh
make destroy-aws DEPLOY_ENV=piotr ${EXTRA_OPTIONS} ROOT_PASS_DIR=jenkins
