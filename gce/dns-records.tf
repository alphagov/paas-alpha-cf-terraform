resource "google_dns_record_set" "wildcard" {
  managed_zone = "${var.dns_zone_id}"
  name = "*.${var.env}.${var.dns_zone_name}"
  type = "A"
  ttl = "60"
  rrdatas = ["${google_compute_forwarding_rule.router_https.ip_address}"]
}
