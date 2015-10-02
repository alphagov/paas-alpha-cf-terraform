resource "google_compute_network" "bastion" {
  name = "${var.env}-cf-bastion"
  ipv4_range = "${var.bastion_cidr}"
}

resource "google_compute_address" "bosh" {
    name = "${var.env}-bosh"
}

resource "google_compute_route" "private_default" {
  name = "${var.env}-private-default"
  dest_range = "0.0.0.0/0"
  network = "${google_compute_network.bastion.name}"
  next_hop_instance = "${google_compute_instance.bastion.name}"
  next_hop_instance_zone = "${google_compute_instance.bastion.zone}"
  priority = 1
  tags = [ "cf" ]
}
