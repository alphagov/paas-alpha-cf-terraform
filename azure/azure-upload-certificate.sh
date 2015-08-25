#!/bin/sh
set -e

openssl req -x509 \
	-key ssh/insecure-deployer \
	-nodes \
	-days 365 -newkey rsa:2048 \
	-out /tmp/insecure-deployer.pem \
	-subj '/CN=www.mydom.com/O=My Company Name LTD./C=US'

openssl x509 \
	-outform der \
	-in /tmp/insecure-deployer.pem \
	-out /tmp/insecure-deployer.pfx

azure service cert create $1-cf-bastion-service /tmp/insecure-deployer.pfx

azure service cert list | \
	grep $1-cf-bastion-service | \
	awk '{print $3}' | tr -d '\n' > ssh_thumbprint

rm -f /tmp/insecure-deployer.{pem,pfx}
