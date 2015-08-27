#!/bin/sh
set -e

if azure service cert list | cat | grep -q $1-cf-bastion-service; then
	echo "There is already a key for this service: $1-cf-bastion-service"
else
	openssl req -x509 \
		-key ssh/insecure-deployer \
		-nodes \
		-days 365 -newkey rsa:2048 \
		-out generated.insecure-deployer.pem \
		-subj '/CN=www.mydom.com/O=My Company Name LTD./C=US'

	openssl x509 \
		-outform der \
		-in generated.insecure-deployer.pem \
		-out generated.insecure-deployer.pfx

	azure config mode asm

	azure service cert create $1-cf-bastion-service generated.insecure-deployer.pfx
fi

azure service cert list | \
	grep $1-cf-bastion-service | \
	awk '{print $3}' | head -n 1 | tr -d '\n' > generated.ssh_thumbprint

