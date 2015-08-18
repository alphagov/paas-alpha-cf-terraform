#!/bin/bash

# Prepare the jumpbox to be able to install ruby and git-based bosh and cf repos
cd $HOME

sudo apt-get update
sudo apt-get install -y build-essential git zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

# Set correct permissions for the ssh key we copied
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub

# start the ssh-agent and add the keys
eval `ssh-agent`
ssh-add ~/.ssh/id_rsa

wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.70-linux-amd64
chmod +x bosh-init-*
./bosh-init-0.0.70-linux-amd64 deploy manifest.yml
