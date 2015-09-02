resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    vars {
        gce_static_ip    =  "${google_compute_address.bosh.address}"
        gce_project_id   =  "${var.gce_project}"
        gce_default_zone =  "${var.gce_region_zone}"
        gce_ssh_user     =  "${var.ssh_user}"
        gce_ssh_key_path =  ".ssh/id_rsa"
        gce_microbosh_net = "${google_compute_network.bastion.name}"
    }
}

resource "google_compute_instance" "bastion" {
  name = "${var.env}-cf-bastion"
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

  provisioner "remote-exec" {
        inline = ["cat << EOF > /home/ubuntu/manifest.yml",
         "${template_file.manifest.rendered}",
         "EOF"]
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer"
          destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer.pub"
          destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file"{
          source = "${path.module}/account.json"
          destination = "/home/ubuntu/account.json"
  }

  provisioner "file" {
      source = "${path.module}/provision.sh"
      destination = "/home/ubuntu/provision.sh"
  }

}



