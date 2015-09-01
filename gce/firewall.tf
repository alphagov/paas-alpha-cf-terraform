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

resource "google_compute_firewall" "boshbosh" {
  name = "${var.env}-boshbosh"
  description = "SSH from trusted external sources"
  network = "${google_compute_network.bastion.name}"

  source_tags = [ "bosh" ]
  target_tags = [ "bosh" ]

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "boshdns" {
  name = "${var.env}-cf-boshdns"
  description = "Allow anything/anywhere to hit port 53 on machines tagges as bosh"
  network = "${google_compute_network.bastion.name}"
  source_ranges = [ "0.0.0.0/0" ]
  target_tags = [ "bosh" ]
  allow {
    protocol = "udp"
    ports = [ 53 ]
  }

}

resource "google_compute_firewall" "bosh-nat" {
  name = "${var.env}-cf-microbosh-nat"
  description = "SSH and Bosh ports from trusted external sources"
  network = "${google_compute_network.bastion.name}"
  source_ranges = [ "0.0.0.0/0" ]
  target_tags = [ "bosh" ]
  allow {
    protocol = "tcp"
    ports = [ 22, 80, 443, 4222, 6868, 25250, 25555, 25777 ]
  }

}





