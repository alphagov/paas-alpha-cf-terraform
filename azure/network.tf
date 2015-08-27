resource "azure_virtual_network" "bastion" {
  name = "${var.env}-bastion-network"
  address_space = ["${var.virtual_network_cidr}"]
  location = "West Europe"

  subnet {
    name = "${var.env}-bastion-subnet"
    address_prefix = "${var.bastion_cidr}"
  }

}

