resource "google_compute_firewall" "ssh" {
  name = "${var.env}-cf-ssh"
  description = "SSH from trusted external sources"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "${split(",", var.office_cidrs)}" ]
  target_tags = [ "bastion", "bosh" ]

  allow {
    protocol = "tcp"
    ports = [ 22 ]
  }
}



# TODO: restrict this better, opening to ports 4222, 6868, 25250, 25555, 25777 is not enough
resource "google_compute_firewall" "internal" {
  name = "${var.env}-cf-internal"
  description = "Open internal communication between instances"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "${var.bastion_cidr}", "${google_compute_address.bosh.address}/32",
                    "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}/32",
                    "${google_compute_instance.bastion.network_interface.0.address}/32" ]
  target_tags = [ "bosh" ]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
    ports = [ 53 ]
  }
}

# TODO: check if you can restrict this better
resource "google_compute_firewall" "haproxy" {
  name = "${var.env}-cf-haproxy"
  description = "Make haproxy server reachable externally"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "0.0.0.0/0" ]
  target_tags = [ "haproxy" ]

  allow {
    protocol = "tcp"
    ports = [ 80, 443, 4443 ]
  }
}
