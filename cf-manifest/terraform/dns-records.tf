resource "aws_route53_record" "wildcard" {
  zone_id = "${var.dns_zone_id}"
  name = "*.${var.env}.${var.dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.router.dns_name}"]
}

resource "aws_route53_record" "bastion" {
  zone_id = "${var.dns_zone_id}"
  name = "${var.env}-bastion.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  records = ["${aws_instance.bastion.public_ip}"]
}

resource "aws_route53_record" "bosh" {
  zone_id = "${var.dns_zone_id}"
  name = "${var.env}-bosh.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  records = ["${aws_eip.bosh.public_ip}"]
}

resource "aws_route53_record" "grafana" {
  zone_id = "${var.dns_zone_id}"
  name = "${var.env}-grafana.${var.dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.graphite.dns_name}"]
}
