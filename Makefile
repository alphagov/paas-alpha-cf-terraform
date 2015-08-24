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
set-azure:
	$(eval dir=azure)

aws: set-aws apply provision
gce: set-gce apply provision
azure: set-azure apply provision

apply-aws: set-aws apply
apply-gce: set-gce apply
apply-azure: set-azure apply
apply: check-env-vars
	@cd ${dir} && terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV}

provision-aws: set-aws provision
provision-gce: set-gce provision
provision-azure: set-azure provision
provision: check-env-vars
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) '/bin/bash provision.sh'

bosh-delete-aws: set-aws bosh-delete
bosh-delete-gce: set-gce bosh-delete
bosh-delete-azure: set-azure bosh-delete
bosh-delete:
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip) './`ls bosh-init-*` delete manifest_${dir}.yml'

destroy-aws: set-aws destroy
destroy-gce: set-gce destroy
destroy-azure: set-azure destroy
destroy:
	@cd ${dir} && terraform destroy -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV}

show-aws: set-aws show
show-gce: set-gce show
show-azure: set-azure show
show:
	@cd ${dir} && terraform show ${DEPLOY_ENV}.tfstate

ssh-aws: set-aws ssh
ssh-gce: set-gce ssh
ssh-azure: set-azure ssh
ssh: check-env-vars
	@ssh -oStrictHostKeyChecking=no ubuntu@$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip)
