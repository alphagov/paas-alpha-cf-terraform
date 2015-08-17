#!/bin/bash

# Prepare the jumpbox to be able to install ruby and git-based bosh and cf repos
cd $HOME

sudo apt-get update
sudo apt-get install -y build-essential git zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

# Set correct permissions for the ssh key we copied
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub

# Generate the key that will be used to ssh between the inception server and the
# microbosh machine
#ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# start the ssh-agent and add the keys
eval `ssh-agent`
#ssh-add ~/.ssh/insecure-deployer
ssh-add ~/.ssh/id_rsa

# account.json file exists
# Variable to replace in Yaml file: ACOUNT_JSON


tr -d '\n' < account.json > account_tmp.json
python -c 'print open("manifest.yml").read().replace("ACCOUNT_JSON", open("account_tmp.json").read()).rstrip().rstrip("EOF")' > manifest_gce.yml 2>&1
rm account_tmp.json

wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.70-linux-amd64
chmod +x bosh-init-*
./bosh-init-0.0.70-linux-amd64 deploy manifest_gce.yml
