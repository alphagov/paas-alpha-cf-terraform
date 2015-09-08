#!/bin/bash
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

# Login to GCE
export CLOUDSDK_PYTHON_SITEPACKAGES=1
ACCOUNT=`json_get account.json client_email`
json_get account.json private_key > gce.key && chmod 600 gce.key
gcloud auth activate-service-account $ACCOUNT --key-file gce.key

echo "Attempting to delete $DEPLOYMENT_NAME-internalbosh route..."
gcloud compute routes delete -q $DEPLOYMENT_NAME-internalbosh
