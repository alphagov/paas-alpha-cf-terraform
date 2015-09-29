#!/bin/bash

go_version=1.5.1
smoke_test_version=4ea03845eeb5237bc5630926356ea223436a28dd

echo Check go version ${go_version}
if [[ ! -d /usr/local/go ]] || [[ "`/usr/local/go/bin/go version`" != *"${go_version}"* ]] ; then
	sudo rm -rf /usr/local/go
	wget https://storage.googleapis.com/golang/go${go_version}.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
	rm go${go_version}.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

echo Retrieving smoke test version ${smoke_test_version}...
[[ ! -d cf-smoke-tests ]] && git clone https://github.com/cloudfoundry/cf-smoke-tests.git
cd cf-smoke-tests
git checkout ${smoke_test_version}
export GOPATH=${HOME}/cf-smoke-tests

echo Run smoke test
CONFIG=$HOME/smoke_test.json bin/test -v
