#!/bin/bash
echo "*** Deploying diego release..."

set -e

DIEGO_RELEASE_URL=https://github.com/cloudfoundry-incubator/diego-release
DIEGO_RELEASE_REVISION=0.1430.0

git_clone() {
  local url=$1
  local revision=$2
  path=$(echo ${url} | sed "s|/$||;s|.*/||;s|.git||")

  if [ ! -d ~/${path}/.git ]; then
    rm -rf ~/${path}
    git clone -q ${url} ~/${path}
  else
    cd ~/${path}
    git remote set-url origin ${url}
    git fetch -q
  fi

  cd ~/${path}
  git checkout -q ${revision}
}

git_clone $DIEGO_RELEASE_URL $DIEGO_RELEASE_REVISION

DIEGO_RELEASE_PATH=~/workspace/diego-release/ ./generate_diego_release.sh aws > diego-manifest.yml

bosh deployment ~/diego-manifest.yml
bosh deploy

