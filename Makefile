.PHONY: all apply provision destroy ssh

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

aws: set-aws apply prepare-provision provision provision-cf-aws
gce: set-gce apply provision

apply-aws: set-aws apply
apply-gce: set-gce apply
apply: check-env-vars
	@cd ${dir} && terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV}

prepare-provision:
	@cd ${dir} && scp -oStrictHostKeyChecking=no provision.sh ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip):provision.sh
	@cd ${dir} && scp -oStrictHostKeyChecking=no manifest.yml ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip):manifest_${dir}.yml

provision-aws: set-aws prepare-provision provision
provision-gce: set-gce provision
provision: check-env-vars
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) '/bin/bash provision.sh'

bosh-delete-aws: set-aws bosh-delete
bosh-delete-gce: set-gce bosh-delete
bosh-delete:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) './bosh-init delete manifest_${dir}.yml'

provision-cf-aws: set-aws provision-cf
provision-cf:
	@cd ${dir} && scp -oStrictHostKeyChecking=no cf-manifest.yml ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip):cf-manifest.yml
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) 'sed -i "s/BOSH_UUID/$$(bosh status --uuid)/" cf-manifest.yml'
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) 'bosh deployment cf-manifest.yml'
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) 'bosh deploy'

destroy-aws: set-aws destroy
destroy-gce: set-gce destroy
destroy:
	@cd ${dir} && terraform destroy -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV}

show-aws: set-aws show
show-gce: set-gce show
show:
	@cd ${dir} && terraform show ${DEPLOY_ENV}.tfstate

ssh-aws: set-aws ssh
ssh-gce: set-gce ssh
ssh: check-env-vars
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip)
