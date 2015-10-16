#CloudFoundry Terraform

To provision a microbosh instance on AWS and GCE.

In order to deploy a microbosh, it is necessary to first create subnets, security groups and static IP reservations which will be used by bosh-init when deploying the microbosh. We are using terraform to create these resources, along with a bastion host which will perform the actual `bosh-init` steps to create the microbosh. Then we use microbosh to deploy Cloud Foundry.

##Pre-requisites

* You will need to be running ssh-agent and have performed an `ssh-add <deployer_key>` to make the credentials available for ssh to be able to connect into the bastion host
* You need to have the [team password store `paas-pass` setup](https://github.gds/multicloudpaas/credentials)
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
* On AWS: Provide AWS access keys as environment variables, plus the corresponding terraform variables. Example in profile:

```
export AWS_ACCESS_KEY_ID=XXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYY
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
```

* On GCE: Pass the AWS credentials to access the shared compile package bucket
  on AWS using the following variables. Specify also the AWS host with the zone.

```
export TF_VAR_GCE_INTEROPERABILITY_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_GCE_INTEROPERABILITY_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export TF_VAR_GCE_INTEROPERABILITY_HOST=s3-eu-west-1.amazonaws.com
```

##Usage
### Build
```
make gce DEPLOY_ENV=<environment_name> # or...
make aws DEPLOY_ENV=<environment_name>
```

This actually includes 3 separate stages:

1. Terraform
2. Provision BOSH
3. Deploy Cloud Foundry

### Destroy

* To destroy everything (stages 1-2-3 above), run:

    ```
    make destroy-gce DEPLOY_ENV=<environment_name> # or...
    make destroy-aws DEPLOY_ENV=<environment_name>
    ```
* To save time the next time you deploy, you can remove Cloud Foundry and other deployments, but keep BOSH running with all its releases, stemcells and compiled packages (stage 3 above):

    ```
    make delete-deployments-gce DEPLOY_ENV=<environment_name> # or...
    make delete-deployments-aws DEPLOY_ENV=<environment_name>
    ```
* You can also delete BOSH separately, provided all the above was deleted (stage 2):

    ```
    make bosh-delete-aws DEPLOY_ENV=<environment_name> # or...
    make bosh-delete-gce DEPLOY_ENV=<environment_name>
    ```

* You can also delete Terraform separately, provided all the above was deleted (stage 1):

    ```
    make destroy-terraform-aws DEPLOY_ENV=<environment_name> # or...
    make destroy-terraform-gce DEPLOY_ENV=<environment_name>
    ```

Known issues
============

GCS with operability mode for compiled packages on GCE
-------------------------------------------------------

On GCE we tried using the GCS in interoperability
mode for compiled package cache, [as described here](https://cloud.google.com/storage/docs/migrating)

```
export TF_VAR_GCE_INTEROPERABILITY_ACCESS_KEY_ID=YYYYYYYYYYY
export TF_VAR_GCE_INTEROPERABILITY_SECRET_ACCESS_KEY=XXXXXXXXXX
export TF_VAR_GCE_INTEROPERABILITY_HOST=storage.googleapi.com
```

But we got random errors using it, like:

```
Failed compiling packages > java/1dab29614aba5dcec2bc03c1dd7c06ad2e803212: Failed to create object, S3 response error: The request signature we calculated does not match the signature you provided. Check your Google secret key and signing method. (00:01:38)
```

As this does not affect the evaluation, we will just use S3 AWS for the time being.
