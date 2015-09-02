# Terraform currently only has limited support for reading environment variables
# Variables for use with terraform must be prefexed with 'TF_VAR_'
# These two variables are passed in as environment variables named:
# TF_VAR_AWS_ACCESS_KEY_ID and TF_VAR_AWS_SECRET_ACCESS_KEY respectively
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}

resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    vars {
        aws_static_ip           =  "${var.microbosh_IP}"
        aws_subnet_id           =  "${aws_subnet.bastion.0.id}"
        aws_availability_zone   = "${var.zones.zone0}"
        aws_secret_access_key   = "${var.AWS_SECRET_ACCESS_KEY}"
        aws_access_key_id       = "${var.AWS_ACCESS_KEY_ID}"
        aws_region              = "${var.region}"
        bosh_security_group     = "${aws_security_group.director.name}"
        default_security_group  = "${aws_security_group.bosh_vm.name}"
    }
}

resource "template_file" "cf_manifest" {
    filename = "${path.module}/cf-manifest.yml.tpl"

    vars {
        aws_subnet_id           = "${aws_subnet.bastion.0.id}"
        aws_availability_zone   = "${var.zones.zone0}"
        default_security_group  = "${aws_security_group.bosh_vm.name}"
        nats_security_group     = "${aws_security_group.nats.name}"
    }
}


