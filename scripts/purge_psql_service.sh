#!/bin/bash
DOMAIN=`python -c 'import yaml; print yaml.load(file("cf-manifest.yml"))["properties"]["domain"]'`
CF_ADMIN="$1"
CF_PASS="$2"

cf api --skip-ssl-validation https://api.${DOMAIN}
echo | cf login -u ${CF_ADMIN} -p ${CF_PASS}
cf target -o admin -s admin

if [[ -z "$(cf apps | grep postgresql-cf-service-broker)" ]] ; then
  echo "PostgreSQL broker  seems to be removed already, skipping..."
else
  echo "*** Removing old PostgreSQL broker..."
  cf delete postgresql-cf-service-broker -f -r  
fi

cf m -s PostgreSQL >/dev/null
if [[ $? != 0 ]] ; then
  echo "PostgreSQL service seems to be removed already, skipping..."
else
  echo "*** Purging old PostgreSQL service..."
  cf purge-service-offering PostgreSQL -f 
fi

