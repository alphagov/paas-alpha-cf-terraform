#! /bin/bash

DIR=$(dirname $0)
cd $DIR

make aws DEPLOY_ENV=piotr
