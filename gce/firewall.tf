resource "google_compute_firewall" "ssh" {
  name = "${var.env}-cf-nat"
  description = "SSH from trusted external sources"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "${split(",", var.office_cidrs)}" ]
  target_tags = [ "bastion" ]

  allow {
    protocol = "tcp"
    ports = [ 22 ]
  }
}
