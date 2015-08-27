resource "azure_virtual_network" "bastion" {
  name = "${var.env}-bastion-network"
  address_space = ["${var.virtual_network_cidr}"]
  location = "West Europe"

  subnet {
    name = "${var.env}-bastion-subnet"
    address_prefix = "${var.bastion_cidr}"
  }
}

# Fake resource to call a external command.
# Creates the network for cloudfoundry
resource "template_file" "cf-network" {
  filename = "/dev/null"
  depends_on = "azure_hosted_service.cf-hosted-service"
  provisioner {
    local-exec {
      # Sadly, sleep 30 to wait for the hosted service to be created in Azure
      command = "sleep 30 &&  ./azure-create-network.sh ${var.env}-cf-hosted-service ${var.env}-cf-network ${var.virtual_network_cidr} ${var.env}-cf-subnet ${var.cf_cidr}"
    }
  }
}

