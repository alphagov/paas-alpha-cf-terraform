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

resource "google_compute_firewall" "bosh" {
  name = "${var.env}-cf-bosh"
  description = "Allow bosh deployed vms to route via bastion"
  network = "${google_compute_network.bastion.name}"

  source_tags = [ "cf", "bastion", "bosh"]
  target_tags = [ "cf", "bastion", "bosh" ]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "internal" {
  name = "${var.env}-cf-internal"
  description = "Open internal communication between instances"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "${var.bastion_cidr}",
                    "${google_compute_address.bosh.address}/32",
                    "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}/32",
                    "${google_compute_instance.bastion.network_interface.0.address}/32" ]
  target_tags = [ "bosh" ]

  allow {
    protocol = "tcp"
    ports = [ 22, 53, 4222, 6868, 25250, 25555, 25777 ]
  }
  allow {
    protocol = "udp"
    ports = [ 53, 3457 ]
  }
}

resource "google_compute_firewall" "web" {
  name = "${var.env}-cf-web"
  description = "Security group for web that allows web traffic from internet"
  network = "${google_compute_network.bastion.name}"

  source_ranges = [ "0.0.0.0/0" ]
  target_tags = [ "router1", "router2" ]

  allow {
    protocol = "tcp"
    ports = [ 80, 443 ]
  }
}
