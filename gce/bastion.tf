resource "google_compute_instance" "bastion" {
  name = "${var.env}-cf-bastion"
  depends_on = [ "template_file.manifest", "template_file.cf-manifest", "template_file.provision" ]
  machine_type = "n1-standard-1"
  zone = "${element(split(",", var.gce_zones), count.index)}"
  disk {
    image = "${var.os_image}"
    size  = 100 // GB
  }
  network_interface {
    network = "${google_compute_network.bastion.name}"
    access_config {}
  }
  metadata {
    sshKeys = "${var.user}:${file("${var.ssh_key_path}")}"
  }
  can_ip_forward = true
  connection {
    user = "${var.ssh_user}"
    key_file = "ssh/insecure-deployer"
  }
  tags = [ "bastion" ]

  provisioner "file" {
          source = "${path.module}/provision.sh"
          destination = "/home/ubuntu/provision.sh"
  }

  provisioner "file" {
          source = "${path.module}/cf-manifest.yml"
          destination = "/home/ubuntu/cf-manifest.yml"
  }

  provisioner "file" {
          source = "${path.module}/manifest.yml"
          destination = "/home/ubuntu/manifest.yml"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer"
          destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer.pub"
          destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file" {
          source = "${path.module}/account.json"
          destination = "/home/ubuntu/account.json"
  }

  provisioner "file" {
          source = "${path.module}/provision.sh"
          destination = "/home/ubuntu/provision.sh"
  }

}