#!/bin/bash
echo "*** Deploying and starting graphite nozzle..."

CF_ADMIN="$1"
CF_PASS="$2"
FIREHOSE_USER="$3"
FIREHOSE_PASS="$4"

DOMAIN=`python -c 'import yaml; print yaml.load(file("cf-manifest.yml"))["properties"]["domain"]'`
DOPPLER_SERVER=`bosh vms | grep doppler_z1/0 | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+'`
GRAPHITE_SERVER=`bosh vms | grep graphite/0 | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+'`

echo "*** Logging in to CF and creating admin space..."
cf api --skip-ssl-validation https://api.${DOMAIN}
echo | cf login -u ${CF_ADMIN} -p ${CF_PASS}
echo | cf create-org admin
cf create-space admin -o admin
cf target -o admin -s admin

git clone https://github.com/CloudCredo/graphite-nozzle go/src/github.com/cloudcredo/graphite-nozzle
cd go/src/github.com/cloudcredo/graphite-nozzle

# The buildpack only supports go1.4.0-2
cat <<EOF | python
import json
j = json.load(open('Godeps/Godeps.json'));
j['GoVersion'] = 'go1.4.2';
f = open('Godeps/Godeps.json','w');
f.write(json.dumps(j, indent=4));
f.close()
EOF

# The sleep 1 is to avoid logs being eaten if the configuration is wrong
# due to this bug: https://github.com/cloudfoundry/loggregator/issues/86
echo "web: sleep 1 && graphite-nozzle" > Procfile

cat <<EOF > manifest.yml
---
applications:
- name: graphite-nozzle
  memory: 100M
  instances: 1
  no-route: true
EOF

cf push --no-start

cf set-env graphite-nozzle DOPPLER_ENDPOINT "ws://${DOPPLER_SERVER}:8081"
cf set-env graphite-nozzle UAA_ENDPOINT "https://uaa.${DOMAIN}"
cf set-env graphite-nozzle STATSD_ENDPOINT "${GRAPHITE_SERVER}:8125"
cf set-env graphite-nozzle FIREHOSE_USERNAME "${FIREHOSE_USER}"
cf set-env graphite-nozzle FIREHOSE_PASSWORD "${FIREHOSE_PASS}"
cf set-env graphite-nozzle SUBSCRIPTION_ID firehose
cf set-env graphite-nozzle STATSD_PREFIX cfstats.
cf set-env graphite-nozzle SKIP_SSL_VALIDATION true

cat <<EOF > graphite-nozzle.json
[
    {"protocol":"tcp","destination":"${DOPPLER_SERVER}","ports":"8081"},
    {"protocol":"udp","destination":"${GRAPHITE_SERVER}","ports":"8125"}
]
EOF
cf create-security-group graphite-nozzle graphite-nozzle.json
cf bind-staging-security-group graphite-nozzle
cf bind-running-security-group graphite-nozzle

cf start graphite-nozzle
