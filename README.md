#CloudFoundry Terraform

To provision a microbosh instance on AWS and GCE.

In order to deploy a microbosh, it is necessary to first create subnets, security groups and static IP reservations which will be used by bosh-init when deploying the microbosh. We are using terraform to create these resources, along with a bastion host which will perform the actual `bosh-init` steps to create the microbosh.

##Pre-requisites
* You will need to be running ssh-agent and have performed an `ssh-add <deployer_key>` to make the credentials available for ssh to be able to connect into the bastion host
* Make available the ssh directory inside aws and gce

```
aws/
    ssh/
        insecure-deployer
        insecure-deployer.pub
gce/
    ssh/
        insecure-deployer
        insecure-deployer.pub
```
* Provide `account.json` inside gce
* Provide AWS access keys as environment variables, plus the corresponding terraform variables. Example in profile:

```
export AWS_ACCESS_KEY_ID=XXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYY
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
```

##Usage
```
make gce DEPLOY_ENV=<environment_name>
```
or...

```
make aws DEPLOY_ENV=<environment_name>
```
See the Makefile for other options.

Please note that although we're using `terraform apply` to create the resources, a corresponding `terraform destroy` operation will be unaware of the microbosh VM that bosh-init creates for us. Before 'terraform destroy' can complete, it will be necessary to ssh into the bastion machine and run './bosh-init delete manifest.yml' - this will trigger bosh-init to delete it's deployment, after which 'terraform destroy' can clean up the rest.

Make commands have been created for this:

* `bosh-delete-aws` / `bosh-delete-gce`
* `destroy-aws` / `destroy-gce`

**Known issue**

The bosh VM creation is currently flaky on GCE. It hangs waiting for ssh to start listening at step:

```
Waiting for the agent on VM 'vm-10ced236-8fd0-4274-4f51-3b2ffdc53c7a' to be ready...
```

One quick workaround is to reset the VM via the GCE console while is waiting,
and the deployment should continue after one seconds. You can restart the VM
with the following `gcloud` command:

```
gcloud compute instances reset --zone europe-west1-b vm-10ced236-8fd0-4274-4f51-3b2ffdc53c7a
```

Otherwise, letting it timeout and reruning the `make` command, it will rerun the `bosh-init` which
will delete the old VM and create a new one. Repeat this step until one works :)
