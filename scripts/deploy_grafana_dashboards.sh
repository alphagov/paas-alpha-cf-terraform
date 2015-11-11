#!/bin/bash

. $(dirname $0)/grafana-lib.sh

GRAPHITE_HOST=$1
GRAFANA_URL=http://${GRAPHITE_HOST}:3000
shift

DATASOURCE_URL=http://127.0.0.1
DATASOURCE_NAME=graphite
DATASOURCE_TYPE=graphite

if grafana_has_data_source ${DATASOURCE_NAME}; then
  info "Grafana: Data source ${DATASOURCE_NAME} already exists"
else
  if grafana_create_data_source ${DATASOURCE_NAME} ${DATASOURCE_TYPE} ${DATASOURCE_URL}; then
    success "Grafana: Data source ${DATASOURCE_NAME} created"
  else
    error "Grafana: Data source ${DATASOURCE_NAME} could not be created"
  fi
fi

for dashboard in $(dirname $0)/grafana_dashboards/*.json; do
  info "Grafana: Uploading dashboard ${dashboard##*/}"
  grafana_upload_dashboard $dashboard
done
