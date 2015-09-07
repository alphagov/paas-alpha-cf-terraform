resource "google_compute_network" "bastion" {
  name = "${var.env}-cf-bastion"
  ipv4_range = "${var.bastion_cidr}"
}

resource "google_compute_address" "bosh" {
    name = "${var.env}-bosh"
}

resource "google_compute_address" "haproxy" {
    name = "${var.env}-haproxy"
}
