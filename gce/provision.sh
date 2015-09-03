#!/bin/bash
STEMCELL=light-bosh-stemcell-2968-google-kvm-ubuntu-trusty-go_agent.tgz
RELEASE=210
BOSH_IP=$1

# Prepare the jumpbox to be able to install ruby and git-based bosh and cf repos
PACKAGES="build-essential git zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 dstat"
if ! dpkg -l $PACKAGES > /dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y $PACKAGES
fi

# Set correct permissions for the ssh key we copied, as TF can't do that yet
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub

# start the ssh-agent and add the keys
eval `ssh-agent`
ssh-add ~/.ssh/id_rsa

# Populate microbosh manifest with GCE credentials
tr -d '\n' < account.json > account_tmp.json
python -c 'print open("manifest.yml").read().replace("ACCOUNT_JSON", open("account_tmp.json").read()).rstrip().rstrip("EOF")' > microbosh-manifest.yml 2>&1
rm account_tmp.json manifest.yml

if [ ! -x bosh-init ]; then
  wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.72-linux-amd64 -O bosh-init
  chmod +x bosh-init
fi
export BOSH_INIT_LOG_LEVEL=debug
export BOSH_INIT_LOG_PATH=bosh-init.log
time ./bosh-init deploy microbosh-manifest.yml

if gem list | grep -q bosh_cli; then
  echo "Bosh cli already installed, skipping..."
else
  echo "Installing bosh cli..."
  time sudo gem install bosh_cli -v 1.3056.0 --no-ri --no-rdoc
fi

export PATH=$PATH:/usr/local/bin/bosh
echo -e "admin\nadmin" | bosh target $BOSH_IP

if [ ! -f $STEMCELL ]; then
  bosh download public stemcell $STEMCELL
fi

time bosh upload stemcell $STEMCELL --skip-if-exists

if [ ! -d cf-release ]; then
  git clone https://github.com/cloudfoundry/cf-release.git
fi

echo "Uploading v210 release to bosh..."
cd cf-release
git checkout v$RELEASE
# time ./update

time bosh upload release releases/cf-$RELEASE.yml

# Deploy CF
cd ~
sed -i "s/BOSH_UUID/$(bosh status --uuid)/" cf-manifest.yml
bosh deployment cf-manifest.yml
time bosh -n deploy
