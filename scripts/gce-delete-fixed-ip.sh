#!/bin/bash
DEPLOYMENT_NAME=${1}

if [ -z "$DEPLOYMENT_NAME" ]; then
  echo "Usage $0 DEPLOY_ENV"
  exit 1
fi

SCRIPT_DIR=$(dirname $0)

. $SCRIPT_DIR/gce-assign-fixed-ip.sh

gcloud_login
gce_delete_fix_routing $DEPLOYMENT_NAME


