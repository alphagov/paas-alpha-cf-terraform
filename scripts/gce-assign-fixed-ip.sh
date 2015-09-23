#!/bin/sh

MICROBOSH_ZONE=${MICROBOSH_ZONE:-europe-west1-b}

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

gcloud_login() {
  # Login to GCE
  export CLOUDSDK_PYTHON_SITEPACKAGES=1
  ACCOUNT=`json_get ~/account.json client_email`
  json_get ~/account.json private_key > ~/gce.key && chmod 600 ~/gce.key
  gcloud auth activate-service-account $ACCOUNT --key-file ~/gce.key
}

gce_delete_fix_routing() {
  DEPLOYMENT_NAME=$1; shift
  echo "Attempting to delete $DEPLOYMENT_NAME-internalbosh route..."
  gcloud compute routes delete -q $DEPLOYMENT_NAME-internalbosh || true
}

# Get the VM CID from the bosh-init status file
gce_get_bosh_vm_cid() {
  json_get bosh-manifest-state.json current_vm_cid
}

gce_set_fix_routing() {
  DEPLOYMENT_NAME=$1; shift
  BOSH_NETWORK_NAME=$1; shift
  BOSH_EXTERNAL_IP=$1; shift

  BOSH_VM=$(gce_get_bosh_vm_cid)

  # Configure internal routing for microbosh
  # 1. Get the real microbosh IP from the VM description
  gcloud compute instances describe --zone $MICROBOSH_ZONE --format json $BOSH_VM > /tmp/microbosh-info.json
  BOSH_INTERNAL_IP=`json_get /tmp/microbosh-info.json networkInterfaces '[0]["networkIP"]'`

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
  if ! gcloud compute routes describe \
    $DEPLOYMENT_NAME-internalbosh --format json >/tmp/internalbosh-route.json 2>/tmp/route.errors; then
    if grep -q "The resource 'projects/.\+/routes/${DEPLOYMENT_NAME}-internalbosh' was not found" /tmp/route.errors; then
      CREATE=true
    else
      echo "Failed retrieving ${DEPLOYMENT_NAME}-internalbosh route information, aborting. Errors:"
      cat /tmp/route.errors
      exit 255
    fi
  else
    # Compare if any of the route attributes need updating
    destRange=`json_get /tmp/internalbosh-route.json destRange`
     priority=`json_get /tmp/internalbosh-route.json priority`
      network=`json_get /tmp/internalbosh-route.json network '.split("/")[-1]'`
    routedest=`json_get /tmp/internalbosh-route.json nextHopInstance '.split("/")[-1]'`

    [[ "$destRange" != "$BOSH_EXTERNAL_IP/32" ]] && UPDATE=true
    [[ "$priority"  != "1" ]] && UPDATE=true
    [[ "$network"   != "$BOSH_NETWORK_NAME" ]] && UPDATE=true
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
    gcloud compute routes create $DEPLOYMENT_NAME-internalbosh \
      --network $DEPLOYMENT_NAME-cf-bastion \
      --destination-range "$BOSH_EXTERNAL_IP/32" \
      --next-hop-instance $BOSH_VM \
      --next-hop-instance-zone $MICROBOSH_ZONE \
      --priority 1 \
      --description Route_packets_for_bosh_external_IP_directly_to_the_microbosh_instance_via_internal_network
    if [[ $? != 0 ]]; then
      echo "Failed creating route, aborting" && exit 103
    fi
  fi
}

