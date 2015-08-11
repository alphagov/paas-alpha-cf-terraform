resource "google_compute_network" "bastion" {
  name = "${var.env}-cf-bastion"
  ipv4_range = "${var.bastion_cidr}"
}
