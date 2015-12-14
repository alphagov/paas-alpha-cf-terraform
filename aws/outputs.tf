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

output "bosh_subnet_id" {
	value = "${aws_subnet.infra.0.id}"
}

output "cf1_subnet_id" {
	value = "${aws_subnet.cf.0.id}"
}

output "cf2_subnet_id" {
	value = "${aws_subnet.cf.1.id}"
}

output "logsearch1_subnet_id" {
	value = "${aws_subnet.logsearch.0.id}"
}

output "logsearch2_subnet_id" {
	value = "${aws_subnet.logsearch.1.id}"
}

output "elb_name" {
	value = "${aws_elb.router.name}"
}

output "graphite_elb_name" {
  value = "${aws_elb.graphite.name}"
}

output "grafana_dns_name" {
  value = "${aws_route53_record.grafana.fqdn}"
}

output "cf_root_domain" {
	value = "${var.env}.${var.dns_zone_name}"
}

output "dns_zone_name" {
        value = "${var.dns_zone_name}"
}

output "bosh_security_group" {
	value = "${aws_security_group.director.name}"
}

output "default_security_group" {
	value = "${aws_security_group.bosh_vm.name}"
}

output "microbosh_static_private_ip" {
	value = "${var.microbosh_IP}"
}

output "microbosh_static_public_ip" {
	value = "${aws_eip.bosh.public_ip}"
}

output "key_pair_name" {
	value = "${var.key_pair_name}"
}

output "compiled_cache_bucket_host" {
	value = "s3-${var.region}.amazonaws.com"
}
