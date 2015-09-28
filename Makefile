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
	$(eval apply_suffix=-var gce_account_json="`tr -d '\n' < account.json`")
bastion:
	$(eval bastion=$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate bastion_ip))

aws: set-aws apply prepare-provision-aws provision
gce: set-gce apply prepare-provision-gce provision

apply-aws: set-aws apply
apply-gce: set-gce apply
apply: check-env-vars
	@cd ${dir} && terraform get && terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV} ${apply_suffix}

manifests/templates/outputs/terraform-outputs-aws.yml: aws/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_yml.rb < aws/${DEPLOY_ENV}.tfstate > manifests/templates/outputs/terraform-outputs-aws.yml
manifests/templates/outputs/terraform-outputs-gce.yml: gce/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_yml.rb < gce/${DEPLOY_ENV}.tfstate > manifests/templates/outputs/terraform-outputs-gce.yml
scripts/terraform-outputs-aws.sh: aws/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_sh.rb < aws/${DEPLOY_ENV}.tfstate > scripts/terraform-outputs-aws.sh
scripts/terraform-outputs-gce.sh: gce/${DEPLOY_ENV}.tfstate
	./scripts/extract_terraform_outputs_to_sh.rb < gce/${DEPLOY_ENV}.tfstate > scripts/terraform-outputs-gce.sh

prepare-provision-aws: set-aws manifests/templates/outputs/terraform-outputs-aws.yml scripts/terraform-outputs-aws.sh prepare-provision
prepare-provision-gce: set-gce manifests/templates/outputs/terraform-outputs-gce.yml scripts/terraform-outputs-gce.sh prepare-provision
prepare-provision: bastion
	@scp -r -oStrictHostKeyChecking=no manifests/templates manifests/generate_deployment_manifest.sh ubuntu@${bastion}:
	@scp -r -oStrictHostKeyChecking=no scripts ubuntu@${bastion}:
	@cd ${dir} && scp -oStrictHostKeyChecking=no manifest.yml ubuntu@${bastion}:bosh-manifest.yml

test-aws: set-aws test
test-gce: set-gce test
test: bastion
	$(eval domain=$(shell terraform output -state=${dir}/${DEPLOY_ENV}.tfstate dns_zone_name))
	smoke_test/smoke_test.json.sh \
	    ${DEPLOY_ENV} ${domain} > \
		smoke_test/smoke_test.json
	@scp -oStrictHostKeyChecking=no \
	    smoke_test/smoke_test.sh smoke_test/smoke_test.json \
	    ubuntu@${bastion}:
	@ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} \
	    '/bin/bash smoke_test.sh'

provision-aws: set-aws prepare-provision-aws provision
provision-gce: set-gce prepare-provision-gce provision
provision: check-env-vars bastion
	@ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} '/bin/bash ./scripts/provision.sh ${dir}'

confirm-execution:
	@read -sn 1 -p "This is a destructive operation, are you sure you want to do this [Y/N]? "; [[ $${REPLY:0:1} = [Yy] ]];

delete-deployment-aws: set-aws delete-deployment
delete-deployment-gce: set-gce delete-deployment
delete-deployment: bastion
	@ssh -oStrictHostKeyChecking=no ubuntu@${bastion} \
	    'for deployment in $$(bosh deployments | cut -f 2 -d "|" | grep -v -e ^+- -e ^$$ -e "total:" -e "Name") ; do bosh -n delete deployment $$deployment --force ; done'

delete-release-aws: set-aws delete-release
delete-release-gce: set-gce delete-release
delete-release: bastion
	@ssh -oStrictHostKeyChecking=no ubuntu@${bastion} \
	    'for release in $$(bosh releases | grep "|" | cut -f 2 -d "|" | grep -v -e "Name") ; do bosh -n delete release $$release --force ; done'

delete-stemcell-aws: set-aws delete-stemcell
delete-stemcell-gce: set-gce delete-stemcell
delete-stemcell: bastion
	@ssh -oStrictHostKeyChecking=no ubuntu@${bastion} \
			'bosh stemcells | grep -v -e + | grep -v -e Name -e "Stemcells total" -e "Currently in-use" | cut -d "|" -f 2,4 | tr "|" " " | grep -v ^$$ | while read -r stemcell; do bosh -n delete stemcell $$stemcell --force; done'

delete-route-gce: bastion
	@ssh -oStrictHostKeyChecking=no ubuntu@${bastion} "/bin/bash ./scripts/gce-delete-fixed-ip.sh ${DEPLOY_ENV}"

bosh-delete-aws: set-aws delete-deployment delete-release delete-stemcell bosh-delete
bosh-delete-gce: set-gce delete-deployment delete-release delete-stemcell bosh-delete delete-route-gce
bosh-delete: bastion
	@ssh -oStrictHostKeyChecking=no ubuntu@${bastion} 'yes | bosh-init delete bosh-manifest.yml'

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
ssh: check-env-vars bastion
	@ssh -oStrictHostKeyChecking=no ubuntu@${bastion}
