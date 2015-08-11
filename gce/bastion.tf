resource "google_compute_instance" "bastion" {
  name = "${var.env}-cf-bastion"
  machine_type = "n1-standard-1"
  zone = "${element(split(",", var.gce_zones), count.index)}"
  disk {
    image = "${var.os_image}"
  }
  network_interface {
    network = "${google_compute_network.bastion.name}"
    access_config { }
  }
  metadata {
    sshKeys = "${var.user}:${file("${var.ssh_key_path}")}"
  }

  tags = [ "bastion" ]
}
