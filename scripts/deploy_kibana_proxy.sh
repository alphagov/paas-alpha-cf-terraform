#!/bin/bash
if [[ -n $(cf app logs | grep running) ]] ; then
  echo "Kibana proxy seems to be running already, skipping deploy..."
  exit 0
fi

echo "*** Deploying and starting Kibana proxy..."
CF_ADMIN="$1"
CF_PASS="$2"
KIBANA_PASSWORD="$3"
KIBANA_SERVER=`python -c 'import yaml; print yaml.load(file("logsearch-manifest.yml"))["meta"]["elasticsearch_master_host"]'`
DOMAIN=`python -c 'import yaml; print yaml.load(file("cf-manifest.yml"))["properties"]["domain"]'`

echo "*** Logging in to CF and creating admin space..."
cf api --skip-ssl-validation https://api.${DOMAIN}
echo | cf login -u ${CF_ADMIN} -p ${CF_PASS}
echo | cf create-org admin
cf create-space admin -o admin
cf target -o admin -s admin

# Create the proxy app
mkdir -p kibana-proxy && cd kibana-proxy

htpasswd -b -c pw kibana ${KIBANA_PASSWORD}

cat <<EOF >nginx.conf
worker_processes 1;
daemon off;
events { worker_connections 1024; }
error_log stderr;
http {
  port_in_redirect off; # Ensure that redirects don't include the internal container PORT - <%= ENV["PORT"] %>
  server_tokens off;
  server {
    listen <%= ENV["PORT"] %>;
    server_name localhost;
    location / {
      proxy_set_header Host kibana;
      proxy_pass http://<%= ENV["KIBANA_SERVER"] %>/;
      auth_basic "KIBANA!";
      auth_basic_user_file ../../pw;
    }
  }
}
EOF

cat <<EOF > manifest.yml
---
applications:
- name: logs
  memory: 100M
  disk: 100M
  instances: 1
  buildpack: staticfile_buildpack
EOF

cf push --no-start
cf set-env logs KIBANA_SERVER ${KIBANA_SERVER}

cat <<EOF > kibana-proxy.json
[{"protocol":"tcp","destination":"${KIBANA_SERVER}","ports":"80,9200"}]
EOF
cf create-security-group kibana-proxy kibana-proxy.json
cf bind-staging-security-group kibana-proxy
cf bind-running-security-group kibana-proxy

cf push 
