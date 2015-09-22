output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "bosh_ip" {
  value = "${aws_eip.bosh.public_ip}"
}

output "environment" {
	value = "${var.env}"
}

output "zone0" {
	value = "${var.zones.zone0}"
}

output "zone1" {
	value = "${var.zones.zone1}"
}

output "region" {
	value = "${var.region}"
}

output "cf1_subnet_id" {
	value = "${aws_subnet.cf.0.id}"
}

output "cf2_subnet_id" {
	value = "${aws_subnet.cf.1.id}"
}

output "aws_secret_access_key" {
	value = "${var.AWS_SECRET_ACCESS_KEY}"
}

output "aws_access_key_id" {
	value = "${var.AWS_ACCESS_KEY_ID}"
}

output "ccdb_address" {
	value = "${aws_db_instance.ccdb.address}"
}

output "ccdb_username" {
	value = "${aws_db_instance.ccdb.username}"
}

output "ccdb_password" {
	value = "${aws_db_instance.ccdb.password}"
}

output "uaadb_address" {
	value = "${aws_db_instance.uaadb.address}"
}

output "uaadb_username" {
	value = "${aws_db_instance.uaadb.username}"
}

output "uaadb_password" {
	value = "${aws_db_instance.uaadb.password}"
}

output "elb_name" {
	value = "${aws_elb.router.name}"
}

output "cf_root_domain" {
	value = "${var.env}.${var.dns_zone_name}"
}
