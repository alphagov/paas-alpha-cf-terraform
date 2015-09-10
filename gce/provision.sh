#!/bin/bash
STEMCELL=light-bosh-stemcell-2968-google-kvm-ubuntu-trusty-go_agent.tgz
RELEASE=210
BOSH_EXTERNAL_IP=$1
MICROBOSH_ZONE=europe-west1-b
DEPLOYMENT_NAME=`python -c 'import yaml; print yaml.load(file("cf-manifest.yml"))["name"]'`

# Returns the $2 field from $1 file, with $3 extra syntax
json_get(){
  value=`python -c "import json; print json.load(file(\"$1\"))[\"$2\"]$3"`
  if [[ $? != 0 ]] ; then
    echo "Error retrieving $2 from $1"
    exit 100
  else
    echo "$value"
  fi
}

# Prepare the jumpbox to be able to install ruby and git-based bosh and cf repos
PACKAGES="build-essential git zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 dstat"
if ! dpkg -l $PACKAGES > /dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y $PACKAGES
fi

# Set correct permissions for the ssh key we copied, as TF can't do that yet
chmod 400 ~/.ssh/id_rsa ~/.ssh/id_rsa.pub ~/account.json

# start the ssh-agent and add the keys
eval `ssh-agent`
ssh-add ~/.ssh/id_rsa

# Login to GCE
export CLOUDSDK_PYTHON_SITEPACKAGES=1
ACCOUNT=`json_get account.json client_email`
json_get account.json private_key > gce.key && chmod 600 gce.key
gcloud auth activate-service-account $ACCOUNT --key-file gce.key

# TODO: Add logic that checks if bosh-init really does re-create mBosh VM and only remove the route then
echo "Attempting to delete $DEPLOYMENT_NAME-internalbosh route..."
gcloud compute routes delete -q $DEPLOYMENT_NAME-internalbosh

# Deploy microbosh server
if [ ! -x bosh-init ]; then
  wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.72-linux-amd64 -O bosh-init
  chmod +x bosh-init
fi
export BOSH_INIT_LOG_LEVEL=debug
export BOSH_INIT_LOG_PATH=bosh-init.log
time ./bosh-init deploy manifest_gce.yml

# Configure internal routing for microbosh
# 1. Get microbosh IP
BOSH_VM=`json_get manifest_gce-state.json current_vm_cid`
gcloud compute instances describe --zone $MICROBOSH_ZONE --format json $BOSH_VM > microbosh-info.json
BOSH_INTERNAL_IP=`json_get microbosh-info.json networkInterfaces '[0]["networkIP"]'`

# 2. Configure iptables on microbosh server
echo "Configuring IPtables on the microbosh..."
RULE="-d $BOSH_EXTERNAL_IP/32 -j DNAT --to-destination $BOSH_INTERNAL_IP"
ssh -T -oStrictHostKeyChecking=no $BOSH_INTERNAL_IP <<EOF
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
for CHAIN in PREROUTING OUTPUT ; do
  echo "Checking \$CHAIN $RULE"
  sudo iptables -t nat -C \$CHAIN $RULE || sudo iptables -t nat -A \$CHAIN $RULE
done
sudo service iptables-persistent save
EOF

# 3. Re-route BOSH_EXTERNAL_IP internally. Check if route exists and is correct first.
CREATE=false
UPDATE=false
gcloud compute routes describe $DEPLOYMENT_NAME-internalbosh --format json >internalbosh-route.json 2>route.errors
if [[ $? != 0 ]] ; then
  grep -q "The resource 'projects/.\+/routes/${DEPLOYMENT_NAME}-internalbosh' was not found" route.errors
  if [[ $? == 0 ]] ; then
    CREATE=true
  else
    echo "Failed retrieving ${DEPLOYMENT_NAME}-internalbosh route information, aborting. Errors:"
    cat route.errors
    exit 255
  fi
else
  # Compare if any of the route attributes need updating
  destRange=`json_get internalbosh-route.json destRange`
   priority=`json_get internalbosh-route.json priority`
    network=`json_get internalbosh-route.json network '.split("/")[-1]'`
  routedest=`json_get internalbosh-route.json nextHopInstance '.split("/")[-1]'`

  [[ "$destRange" != "$BOSH_EXTERNAL_IP/32" ]] && UPDATE=true
  [[ "$priority"  != "1" ]] && UPDATE=true
  [[ "$network"   != "$DEPLOYMENT_NAME-cf-bastion" ]] && UPDATE=true
  [[ "$routedest" != "$BOSH_VM" ]] && UPDATE=true

  # In GCE, you can't update routes, you have to delete and create new
  if $UPDATE ; then
    echo "Route needs updating, deleting..."
    gcloud compute routes delete -q $DEPLOYMENT_NAME-internalbosh
    [[ $? != 0 ]] && echo "Need to update the route, but failed to delete, aborting" && exit 102
    CREATE=true
  fi
fi

if $CREATE ; then
  echo "Creating $DEPLOYMENT_NAME-internalbosh route..."
  gcloud compute routes create $DEPLOYMENT_NAME-internalbosh --network $DEPLOYMENT_NAME-cf-bastion --destination-range "$BOSH_EXTERNAL_IP/32" --next-hop-instance $BOSH_VM --next-hop-instance-zone $MICROBOSH_ZONE --priority 1 --description Route_packets_for_bosh_external_IP_directly_to_the_microbosh_instance_via_internal_network
  [[ $? != 0 ]] && echo "Failed creating route, aborting" && exit 103
fi

# Install BOSH CLI and log in
if gem list | grep -q bosh_cli; then
  echo "Bosh cli already installed, skipping..."
else
  echo "Installing bosh cli..."
  time sudo gem install bosh_cli -v 1.3056.0 --no-ri --no-rdoc
fi
export PATH=$PATH:/usr/local/bin/bosh
echo -e "admin\nadmin" | bosh target $BOSH_EXTERNAL_IP

# Upload stemcell
if [ ! -f $STEMCELL ]; then
  wget http://storage.googleapis.com/bosh-stemcells/$STEMCELL
fi
time bosh upload stemcell $STEMCELL --skip-if-exists

# Git clone and upload release
if [ ! -d cf-release ]; then
  git clone https://github.com/cloudfoundry/cf-release.git
fi

echo "Uploading v$RELEASE release to bosh..."
cd cf-release
git checkout v$RELEASE
# time ./update

time bosh upload release releases/cf-$RELEASE.yml

# Deploy CF
cd ~
sed -i "s/BOSH_UUID/$(bosh status --uuid)/" cf-manifest.yml
bosh deployment cf-manifest.yml
time bosh -n deploy

#TODO: run CATS (CF acceptance tests) to verify deployment health
