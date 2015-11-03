#!/bin/bash
if [[ -n $(cf app postgresql-cf-service-broker | grep running) ]] ; then
  echo "PostgreSQL broker seems to be running already, skipping deploy..."
  exit 0
fi
echo "*** Deploying and registering PostgreSQL broker..."

PSQL_SERVER=`bosh vms | grep postgres/0 | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+'`
DOMAIN=`python -c 'import yaml; print yaml.load(file("cf-manifest.yml"))["properties"]["domain"]'`
CF_ADMIN="$1"
CF_PASS="$2"
PSQL_ADMIN_USER="$3"
PSQL_ADMIN_PASS="$4"

PACKAGES="maven openjdk-7-jdk"
if ! dpkg -l $PACKAGES > /dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y $PACKAGES
fi

echo "*** Logging in to CF and creating admin space..."
cf api --skip-ssl-validation https://api.${DOMAIN}
echo | cf login -u ${CF_ADMIN} -p ${CF_PASS}
echo | cf create-org admin
cf create-space admin -o admin
cf target -o admin -s admin

if [ ! -d postgresql-cf-service-broker ]; then
  git clone https://github.com/cloudfoundry-community/postgresql-cf-service-broker.git
fi

cd postgresql-cf-service-broker
git checkout 5eb470f027f803d7de3117add71630aac08ba33c

mvn package -DskipTests

cf push postgresql-cf-service-broker -p target/postgresql-cf-service-broker-2.3.0-SNAPSHOT.jar --no-start
cd ..

# Cofigure security
echo '[{"protocol":"tcp","destination":"10.0.0.0/8","ports":"5432"}]' >internal-psql.json
cf create-security-group internal-postgresql internal-psql.json
cf bind-staging-security-group internal-postgresql
cf bind-running-security-group internal-postgresql

cf set-env postgresql-cf-service-broker JAVA_OPTS "-Dsecurity.user.password=${PSQL_ADMIN_PASS}"
cf set-env postgresql-cf-service-broker MASTER_JDBC_URL "jdbc:postgresql://${PSQL_SERVER}:5432/psqlbroker?user=${PSQL_ADMIN_USER}&password=${PSQL_ADMIN_PASS}"
cf start postgresql-cf-service-broker
URL=`cf app postgresql-cf-service-broker | grep urls: | awk '{print $2}'`

# Only register if not done already
cf service-brokers | grep -q ${URL}
if [[ ! $? == 0 ]] ; then
  cf create-service-broker postgresql-cf-service-broker user ${PSQL_ADMIN_PASS} http://${URL}
  cf enable-service-access PostgreSQL -p "Basic PostgreSQL Plan"
fi
