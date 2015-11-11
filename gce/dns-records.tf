resource "google_dns_record_set" "wildcard" {
  managed_zone = "${var.dns_zone_id}"
  name = "*.${var.env}.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  rrdatas = ["${google_compute_forwarding_rule.router_https.ip_address}"]
}

resource "google_dns_record_set" "bastion" {
  managed_zone = "${var.dns_zone_id}"
  name = "${var.env}-bastion.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  rrdatas = ["${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}"]
}

resource "google_dns_record_set" "bosh" {
  managed_zone = "${var.dns_zone_id}"
  name = "${var.env}-bosh.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  rrdatas = ["${google_compute_address.bosh.address}"]
}

resource "google_dns_record_set" "grafana" {
  managed_zone = "${var.dns_zone_id}"
  name = "${var.env}-grafana.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  rrdatas = ["${google_compute_address.graphite.address}"]
}
