#!/bin/bash

# Prepare the jumpbox to be able to install ruby and git-based bosh and cf repos
cd $HOME

PACKAGES="build-essential git zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3"
if ! dpkg -l $PACKAGES > /dev/null 2>&1; then
	sudo apt-get update
	sudo apt-get install -y $PACKAGES
fi

# Set correct permissions for the ssh key we copied
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub

# start the ssh-agent and add the keys
eval `ssh-agent`
#ssh-add ~/.ssh/insecure-deployer
ssh-add ~/.ssh/id_rsa

if [ ! -x bosh-init ]; then
	wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.72-linux-amd64 -O bosh-init
	chmod +x bosh-init
fi

./bosh-init deploy manifest.yml
