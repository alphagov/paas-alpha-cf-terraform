#!/bin/bash

go_version=1.5.1
cf_version=6.12.3
smoke_test_version=4ea03845eeb5237bc5630926356ea223436a28dd


echo Check go version ${go_version}
if [[ ! -d /usr/local/go ]] || [[ "`/usr/local/go/bin/go version`" != *"${go_version}"* ]] ; then
	sudo rm -rf /usr/local/go
	wget https://storage.googleapis.com/golang/go${go_version}.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
	rm go${go_version}.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

echo Check cloud foundry cli version ${cf_version}
if ! cf_version_orig=`dpkg-query -W cf-cli` || [[ "${cf_version_orig}" != *"${cf_version}"* ]]; then
	sudo dpkg -r cf-cli
	wget -O cf-cli_${cf_version}_amd64.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_version}&source=github-rel"
	sudo dpkg -i cf-cli_${cf_version}_amd64.deb
fi

echo Retrieving smoke test version ${smoke_test_version}...
[[ ! -d cf-smoke-tests ]] && git clone https://github.com/cloudfoundry/cf-smoke-tests.git
cd cf-smoke-tests
git checkout ${smoke_test_version}
export GOPATH=${HOME}/cf-smoke-tests

echo Run smoke test
CONFIG=$HOME/smoke_test.json bin/test -v 
