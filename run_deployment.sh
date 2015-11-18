#! /bin/bash

export TF_VAR_AWS_ACCESS_KEY_ID=$1
export TF_VAR_AWS_SECRET_ACCESS_KEY=$2

DIR=$(dirname $0)
cd $DIR

#make aws DEPLOY_ENV=piotr
env
