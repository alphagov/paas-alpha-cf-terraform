#!/bin/bash
echo "*** Deploying and starting syslog nozzle..."

CF_ADMIN="$1"
CF_PASS="$2"

# For now we are using cf admin user, but we should create more secure
# syslog nozzle client. Graphite-nozzle client doesn't have broad enough credentials for syslog nozzle
#FIREHOSE_USER="$3"
#FIREHOSE_PASS="$4"
# Alternatively you can create user: cf create-user syslog syslog
# And then add this user to firehose group: uaac member add doppler.firehose syslog
# For this you need cf-uaac gem and login as admin so that you can manipulate users


DOMAIN=`python -c 'import yaml; print yaml.load(file("cf-manifest.yml"))["properties"]["domain"]'`
DOPPLER_SERVER=`bosh vms | grep doppler_z1/0 | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+'`
LOGSEARCH_SERVER=`bosh vms | grep logsearch/0 | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+'`

echo "*** Logging in to CF and creating admin space..."
cf api --skip-ssl-validation https://api.${DOMAIN}
echo | cf login -u ${CF_ADMIN} -p ${CF_PASS}
echo | cf create-org admin
cf create-space admin -o admin
cf target -o admin -s admin


git clone https://github.com/cloudfoundry-community/firehose-to-syslog.git
cd firehose-to-syslog
git checkout 02ace5f9b80068f4384cc0d1e98b2c0c019ca43f

# The sleep 1 is to avoid logs being eaten if the configuration is wrong
# due to this bug: https://github.com/cloudfoundry/loggregator/issues/86
echo "web: sleep 1 && firehose-to-syslog" > Procfile

cat <<EOF > manifest.yml
---
applications:
- name: firehose-to-syslog
  buildpack: https://github.com/cloudfoundry/go-buildpack.git
  memory: 1G
  no-route: true
EOF

cf push --no-start

cf set-env firehose-to-syslog DOPPLER_ENDPOINT "ws://${DOPPLER_SERVER}:8081"
cf set-env firehose-to-syslog FIREHOSE_USER "${CF_ADMIN}"
cf set-env firehose-to-syslog FIREHOSE_PASSWORD "${CF_PASS}"
cf set-env firehose-to-syslog FIREHOSE_SUBSCRIPTION_ID syslog-nozzle
cf set-env firehose-to-syslog SKIP_SSL_VALIDATION true
cf set-env firehose-to-syslog API_ENDPOINT "https://api.${DOMAIN}"
cf set-env firehose-to-syslog SYSLOG_ENDPOINT "${LOGSEARCH_SERVER}:5514"

# Default events are LogMessage only, uncomment if you want log all
#cf set-env firehose-to-syslog EVENTS "LogMessage,ValueMetric,CounterEvent,Error,ContainerMetric,Heartbeat,HttpStart,HttpStop,HttpStartStop"

# Extra fields you want to annotate your events with, example: "env:dev,something:other"
#cf set-env firehose-to-syslog EXTRA_FIELDS "..."


cat <<EOF > syslog-nozzle.json
[
    {"protocol":"tcp","destination":"${DOPPLER_SERVER}","ports":"8081"},
    {"protocol":"tcp","destination":"${LOGSERACH_SERVER}","ports":"5514"}
]
EOF

cf create-security-group syslog-nozzle syslog-nozzle.json
cf bind-staging-security-group syslog-nozzle
cf bind-running-security-group syslog-nozzle

cf start firehose-to-syslog 
