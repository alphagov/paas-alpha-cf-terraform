# Terraform currently only has limited support for reading environment variables
# Variables for use with terraform must be prefexed with 'TF_VAR_'
# These two variables are passed in as environment variables named:
# TF_VAR_AWS_ACCESS_KEY_ID and TF_VAR_AWS_SECRET_ACCESS_KEY respectively
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}

resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    vars {
        aws_static_ip           = "${var.microbosh_IP}"
        aws_public_ip           = "${aws_eip.bosh.public_ip}"
        aws_subnet_id           = "${aws_subnet.infra.0.id}"
        aws_availability_zone   = "${var.zones.zone0}"
        aws_secret_access_key   = "${var.AWS_SECRET_ACCESS_KEY}"
        aws_access_key_id       = "${var.AWS_ACCESS_KEY_ID}"
        aws_region              = "${var.region}"
        bosh_security_group     = "${aws_security_group.director.name}"
        default_security_group  = "${aws_security_group.bosh_vm.name}"
    }

    provisioner "local-exec" {
      command = "echo '${template_file.manifest.rendered}' > manifest.yml"
    }
}

resource "template_file" "cf_stub" {
    filename = "${path.module}/cf-stub.yml.tpl"

    vars {
        default_security_group  = "${aws_security_group.bosh_vm.name}"
        environment             = "${var.env}"
        zone0                   = "${var.zones.zone0}"
        zone1                   = "${var.zones.zone1}"
        cf1_subnet_id           = "${aws_subnet.cf.0.id}"
        cf2_subnet_id           = "${aws_subnet.cf.1.id}"
    }

    provisioner "local-exec" {
      command = "echo '${template_file.cf_stub.rendered}' > cf-stub.yml"
    }
}
