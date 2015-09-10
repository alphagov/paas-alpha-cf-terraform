.PHONY: all apply provision destroy ssh
SHELL := /bin/bash

all:
	$(error Usage: make <aws|gce> DEPLOY_ENV=name)

check-env-vars:
ifndef DEPLOY_ENV
    $(error Must pass DEPLOY_ENV=<name>)
endif

set-aws:
	$(eval dir=aws)
set-gce:
	$(eval dir=gce)

aws: set-aws apply prepare-provision provision
gce: set-gce apply prepare-provision provision

apply-aws: set-aws apply
apply-gce: set-gce apply
apply: check-env-vars
	@cd ${dir} && terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV}

confirm-execution:
	@read -sn 1 -p "This is a destructive operation, are you sure you want to do this [Y/N]? "; [[ $${REPLY:0:1} = [Yy] ]];

prepare-provision:
	@cd ${dir} && scp -oStrictHostKeyChecking=no provision.sh ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip):provision.sh
	@cd ${dir} && scp -oStrictHostKeyChecking=no cf-stub.yml ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip):cf-stub.yml
	@cd ${dir} && scp -oStrictHostKeyChecking=no manifest.yml ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip):manifest_${dir}.yml

provision-aws: set-aws prepare-provision provision
provision-gce: set-gce prepare-provision provision
provision: check-env-vars
	@ssh -t -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) '/bin/bash provision.sh $(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bosh_ip)'

delete-deployment-aws: set-aws delete-deployment
delete-deployment-gce: set-gce delete-deployment
delete-deployment:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) \
	    'for deployment in $$(bosh deployments | cut -f 2 -d "|" | grep -v -e ^+- -e ^$$ -e "total:" -e "Name") ; do bosh -n delete deployment $$deployment --force ; done'

delete-release-aws: set-aws delete-release
delete-release-gce: set-gce delete-release
delete-release:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) \
	    'for release in $$(bosh releases | grep "|" | cut -f 2 -d "|" | grep -v -e "Name") ; do bosh -n delete release $$release --force ; done'

delete-stemcell-aws: set-aws delete-stemcell
delete-stemcell-gce: set-gce delete-stemcell
delete-stemcell:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) \
			'bosh stemcells | grep -v -e + | grep -v -e Name -e "Stemcells total" -e "Currently in-use" | cut -d "|" -f 2,4 | tr "|" " " | grep -v ^$$ | while read -r stemcell; do bosh -n delete stemcell $$stemcell --force; done'

delete-route-gce:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) '/bin/bash ./delete-route.sh'

bosh-delete-aws: set-aws delete-deployment delete-release delete-stemcell bosh-delete
bosh-delete-gce: set-gce delete-deployment delete-release delete-stemcell bosh-delete delete-route-gce
bosh-delete:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) 'yes | ./bosh-init delete manifest_${dir}.yml'

destroy-aws: confirm-execution set-aws bosh-delete-aws destroy
destroy-gce: confirm-execution set-gce bosh-delete-gce destroy
destroy:
	@cd ${dir} && terraform destroy -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV} -force

show-aws: set-aws show
show-gce: set-gce show
show:
	@cd ${dir} && terraform show ${DEPLOY_ENV}.tfstate

ssh-aws: set-aws ssh
ssh-gce: set-gce ssh
ssh: check-env-vars
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip)
