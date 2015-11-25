.PHONY: all apply provision destroy ssh
SHELL := /bin/bash

ROOT_PASS_DIR ?= .

all:
	$(error Usage: make <aws|gce> DEPLOY_ENV=name)

check-env-vars:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))

set-aws: update-paas-pass
	$(eval dir=aws)
set-gce: update-paas-pass
	$(eval dir=gce)
	$(eval apply_suffix=-var gce_account_json="`tr -d '\n' < account.json`")
bastion: check-env-vars
	$(eval bastion=$(shell DEPLOY_ENV=${DEPLOY_ENV} ./scripts/get_bastion_host.sh ${dir}))

aws: check-env-vars set-aws apply prepare-provision-aws provision
gce: check-env-vars set-gce apply prepare-provision-gce provision

apply-aws: set-aws apply
apply-gce: set-gce apply
apply: check-env-vars
	cd ${dir} && terraform get && terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV} ${WEB_ACCESS_OPTION} ${apply_suffix} \
		|| terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV} ${WEB_ACCESS_OPTION} ${apply_suffix}

manifests/templates/outputs/terraform-outputs-aws.yml: check-env-vars aws/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_yml.rb < aws/${DEPLOY_ENV}.tfstate > manifests/templates/outputs/terraform-outputs-aws.yml
manifests/templates/outputs/terraform-outputs-gce.yml: check-env-vars gce/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_yml.rb < gce/${DEPLOY_ENV}.tfstate > manifests/templates/outputs/terraform-outputs-gce.yml
scripts/terraform-outputs-aws.sh: check-env-vars aws/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_sh.rb < aws/${DEPLOY_ENV}.tfstate > scripts/terraform-outputs-aws.sh
scripts/terraform-outputs-gce.sh: check-env-vars gce/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_sh.rb < gce/${DEPLOY_ENV}.tfstate > scripts/terraform-outputs-gce.sh

prepare-provision-aws: set-aws manifests/templates/outputs/terraform-outputs-aws.yml scripts/terraform-outputs-aws.sh prepare-provision
prepare-provision-gce: set-gce manifests/templates/outputs/terraform-outputs-gce.yml scripts/terraform-outputs-gce.sh prepare-provision
prepare-provision: check-env-vars bastion
	scp -r -oStrictHostKeyChecking=no manifests/templates \
	    manifests/generate_bosh_manifest.sh \
	    ubuntu@${bastion}:
	scp -r -oStrictHostKeyChecking=no scripts ubuntu@${bastion}:
	PASSWORD_STORE_DIR=~/.paas-pass pass ${ROOT_PASS_DIR}/cloudfoundry/bosh-secrets.yml | \
	    ssh -oStrictHostKeyChecking=no ubuntu@${bastion} 'cat > templates/bosh-secrets.yml'

provision-aws: set-aws prepare-provision-aws provision
provision-gce: set-gce prepare-provision-gce provision
provision: check-env-vars bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} '/bin/bash ./scripts/provision.sh ${dir}'

confirm-execution:
	@if test "${SKIP_CONFIRM}" = "" ; then \
		read -sn 1 -p "This is a destructive operation, are you sure you want to do this [Y/N]? "; [[ $${REPLY:0:1} = [Yy] ]]; \
	fi

delete-deployments-aws: set-aws delete-deployments
delete-deployments-gce: set-gce delete-deployments
delete-deployments: check-env-vars confirm-execution bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} './scripts/bosh_delete_deployments.rb -y'

delete-release-aws: set-aws delete-release
delete-release-gce: set-gce delete-release
delete-release: check-env-vars bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} \
	    'for release in $$(bosh releases | grep "|" | cut -f 2 -d "|" | grep -v -e "Name") ; do bosh -n delete release $$release --force ; done'

delete-stemcell-aws: set-aws delete-stemcell
delete-stemcell-gce: set-gce delete-stemcell
delete-stemcell: check-env-vars bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} \
			'bosh stemcells | grep -v -e + | grep -v -e Name -e "Stemcells total" -e "Currently in-use" | cut -d "|" -f 2,4 | tr "|" " " | grep -v ^$$ | while read -r stemcell; do bosh -n delete stemcell $$stemcell --force; done'

destroy-terraform-aws: confirm-execution set-aws destroy-terraform
destroy-terraform-gce: confirm-execution set-gce destroy-terraform
destroy-terraform: check-env-vars
	cd ${dir} && terraform destroy -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV} ${WEB_ACCESS_OPTION} ${apply_suffix} -force

bosh-delete-aws: set-aws delete-deployments delete-release delete-stemcell bosh-delete
bosh-delete-gce: set-gce delete-deployments delete-release delete-stemcell bosh-delete
bosh-delete: bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} 'yes | bosh-init delete bosh-manifest.yml'

destroy-aws: confirm-execution set-aws delete-deployments bosh-delete-aws destroy-terraform
destroy-gce: confirm-execution set-gce delete-deployments bosh-delete-gce destroy-terraform

show-aws: set-aws show
show-gce: set-gce show
show: check-env-vars
	cd ${dir} && terraform show ${DEPLOY_ENV}.tfstate

ssh-aws: set-aws ssh
ssh-gce: set-gce ssh
ssh: check-env-vars bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} ${CMD}

update-paas-pass:
	PASSWORD_STORE_DIR=~/.paas-pass pass git pull --rebase
