#!/bin/bash
set -e

RELEASE="v226"
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
tmpdir="job_property_extract.{$RANDOM}"
mkdir -p "/tmp/${tmpdir}"
pushd "/tmp/${tmpdir}"

git clone https://github.com/cloudfoundry/cf-release.git
cd cf-release
git checkout "${RELEASE}"
git submodule update --init --recursive
find -name 'spec' -type f | grep 'jobs' | xargs ${SCRIPT_DIR}/extract_job_spec.rb
cp job_specs.yml ${SCRIPT_DIR}

popd
rm -rf "/tmp/${tmpdir}"
