resource "google_compute_firewall" "ssh" {
  name = "${var.env}-cf-nat"
  description = "SSH from trusted external sources"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "${split(",", var.office_cidrs)}" ]
  target_tags = [ "bastion","bosh" ]

  allow {
    protocol = "tcp"
    ports = [ 22 ]
  }
}

resource "google_compute_firewall" "bosh-nat" {
  name = "${var.env}-cf-microbosh-nat"
  description = "SSH and Bosh ports from trusted external sources"
  network = "${google_compute_network.bastion.name}"
  source_ranges = [ "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}" ]
  target_tags = [ "bosh" ]
  allow {
    protocol = "tcp"
    ports = [ 22, 4222, 6868, 25250, 25555, 25777 ]
  }

}



