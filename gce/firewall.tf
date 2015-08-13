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

resource "google_compute_firewall" "ssh-bosh" {
  name = "${var.env}-cf-microbosh"
  description = "SSH from trusted external sources"
  network = "${google_compute_network.bastion.name}"
  target_tags = [ "bosh" ]
  allow {
    protocol = "tcp"
    ports = [ 22, 4222, 6868, 25250, 25555, 25777 ]
  }

}