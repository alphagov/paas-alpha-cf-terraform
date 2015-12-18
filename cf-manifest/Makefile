.PHONY: all check-env-vars bastion terraform-world upload-deployment upload-secrets deploy-bosh deploy-cf
SHELL := /bin/bash
ROOT_PASS_DIR ?= .
SSL_CERTIFICATES_FILE := cloudfoundry/cf-dev-ssl-certificates.yml

aws: check-env-vars terraform-world upload-deployment upload-secrets deploy-bosh deploy-cf

check-env-vars:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))

bastion: check-env-vars
	$(eval bastion=$(shell DEPLOY_ENV=${DEPLOY_ENV} ./scripts/get_bastion_host.sh))

terraform-world: check-env-vars
	cd terraform && terraform get && terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV} \
		|| terraform apply -state=${DEPLOY_ENV}.tfstate -var env=${DEPLOY_ENV}

outputs/terraform-outputs.yml: check-env-vars terraform/${DEPLOY_ENV}.tfstate
	scripts/extract_terraform_outputs_to_yml.rb < terraform/${DEPLOY_ENV}.tfstate > outputs/terraform-outputs.yml
outputs/terraform-outputs.sh: check-env-vars terraform/${DEPLOY_ENV}.tfstate
	scripts/extract_terraform_outputs_to_sh.rb < terraform/${DEPLOY_ENV}.tfstate > outputs/terraform-outputs.sh

upload-deployment: check-env-vars bastion outputs/terraform-outputs.yml outputs/terraform-outputs.sh
	scp -r -oStrictHostKeyChecking=no deployments ubuntu@${bastion}:
	scp -r -oStrictHostKeyChecking=no outputs ubuntu@${bastion}:
	scp -r -oStrictHostKeyChecking=no scripts ubuntu@${bastion}:

upload-secrets: check-env-vars bastion
	PASSWORD_STORE_DIR=~/.paas-pass pass ${ROOT_PASS_DIR}/cloudfoundry/cf-secrets.yml | \
		ssh -oStrictHostKeyChecking=no ubuntu@${bastion} 'cat > ./outputs/cf-secrets.yml'
	PASSWORD_STORE_DIR=~/.paas-pass pass ${ROOT_PASS_DIR}/cloudfoundry/bosh-secrets.yml | \
		ssh -oStrictHostKeyChecking=no ubuntu@${bastion} 'cat > ./outputs/bosh-secrets.yml'
	PASSWORD_STORE_DIR=~/.paas-pass pass ${ROOT_PASS_DIR}/${SSL_CERTIFICATES_FILE} | \
		ssh -oStrictHostKeyChecking=no ubuntu@${bastion} 'cat > ./outputs/cf-ssl-certificates.yml'

deploy-bosh: check-env-vars bastion 
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} '/bin/bash ./scripts/deploy_bosh.sh'

deploy-cf: check-env-vars bastion
	ssh -t -oStrictHostKeyChecking=no ubuntu@${bastion} '/bin/bash ./scripts/deploy_cf.sh'
