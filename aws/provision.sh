#!/bin/bash
STEMCELL=bosh-stemcell-3056-aws-xen-ubuntu-trusty-go_agent.tgz

# Prepare the jumpbox to be able to install ruby and git-based bosh and cf repos
sudo apt-get update
sudo apt-get install -y build-essential git zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 dstat

# Set correct permissions for the ssh key we copied
# TF feature request: https://github.com/hashicorp/terraform/issues/3071
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub

# start the ssh-agent and add the keys
eval `ssh-agent`
ssh-add ~/.ssh/id_rsa

# TODO: download bosh-init from our own bucket
wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.72-linux-amd64 -O bosh-init
chmod +x bosh-init
export BOSH_INIT_LOG_LEVEL=debug
export BOSH_INIT_LOG_PATH=bosh_init.log
time ./bosh-init deploy manifest_aws.yml

# TODO: install bosh cli rubygems in parallel to bosh-init (which mainly stresses bosh server)
echo "Installing bosh cli..."
time sudo gem install bosh_cli -v 1.3056.0 --no-ri --no-rdoc
export PATH=$PATH:/usr/local/bin/bosh

# FIXME: make passwords properly strong
# FIXME: bosh for some reason ignores name and sets it to "my-bosh"
# FIXME: cmd below works, but bosh compains 'stty: standard input: Inappropriate ioctl for device'
echo -e "admin\nadmin" | bosh target 10.0.0.6 "IamIgnored"

# TODO: download stemcell from our own bucket using multiple threads, in paralell with other tasks
time bosh download public stemcell $STEMCELL
time bosh upload stemcell $STEMCELL

# TODO: this can also happen in parallel
time git clone https://github.com/cloudfoundry/cf-release.git -b v215

# TODO: pre-seed bosh cache, otherwise action below takes forever...
# FIXME: make output from bosh command stream and have color. It takes quite some time to complete, immediate output is desirable.
# (this script is run via ssh from makefile)

# No, you can't bosh upload release cf-release/releases/cf-215.yml, you have to CD into the cf-release first
echo "Uploading v215 release to bosh..."
cd cf-release
time bosh upload release releases/cf-215.yml
