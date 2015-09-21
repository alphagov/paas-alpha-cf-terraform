resource "google_compute_instance" "bastion" {
  name = "${var.env}-cf-bastion"
  depends_on = [ "template_file.manifest", "template_file.cf-manifest", "google_compute_firewall.ssh" ]
  machine_type = "n1-standard-1"
  zone = "${lookup(var.zones, concat("zone", count.index))}"
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
          source = "${path.module}/delete-route.sh"
          destination = "/home/ubuntu/delete-route.sh"
  }

   provisioner "file" {
          source = "${path.module}/../scripts/deploy_psql_broker.sh"
          destination = "/home/ubuntu/deploy_psql_broker.sh"
  }

  provisioner "file" {
        source = "${module.smoke_test.script_path}"
        destination = "/home/ubuntu/smoke_test.sh"
  }

}

module "smoke_test" {
  source = "../smoke_test"

  haproxy_ip = "${google_compute_address.haproxy.address}"
  env = "${var.env}"

}
