resource "azure_virtual_network" "default" {
  name = "${var.env}-default-network"
  address_space = ["${var.virtual_network_cidr}"]
  location = "West Europe"

  subnet {
    name = "${var.env}-cf-bastion"
    address_prefix = "${var.bastion_cidr}"
  }

}

