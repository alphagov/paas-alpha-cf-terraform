#!/bin/bash

set -euo pipefail # fail on error
export PATH=/opt/puppetlabs/puppet/bin/:$PATH
cd $(dirname $0)

PUPPET_LABS_RELEASE_DEB=https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb

echo "Installing puppet system packages..."
if ! dpkg -l puppetlabs-release-pc1  > /dev/null 2>&1; then
  wget $PUPPET_LABS_RELEASE_DEB
  sudo dpkg -i  ${PUPPET_LABS_RELEASE_DEB##*/}
fi

PACKAGES="
  puppet-agent
"
if ! dpkg -l puppet-agent  > /dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install puppet-agent -y
fi

[ -x /opt/puppetlabs/puppet/bin/librarian-puppet ] || \
  time sudo /opt/puppetlabs/puppet/bin/gem install librarian-puppet --no-rdoc --no-ri

/opt/puppetlabs/puppet/bin/librarian-puppet install

sudo /opt/puppetlabs/puppet/bin/puppet apply --modulepath=./modules provision.pp

