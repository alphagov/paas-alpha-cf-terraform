resource "azure_security_group" "bastion" {
    name = "${var.env}-bastion"
    location = "West Europe"
}
resource "azure_security_group_rule" "bastion_ssh_access" {
    count = "${length(split(",", "${var.office_cidrs}"))}"
    name = "${var.env}-bastion-ssh-access-rule-${count.index}"
    security_group_names = ["${azure_security_group.bastion.name}"]
    type = "Inbound"
    action = "Allow"
    priority = "20${count.index}"
    source_address_prefix = "${element(split(",", "${var.office_cidrs}"), count.index)}"
    source_port_range = "*"
    destination_address_prefix = "${azure_instance.bastion.vip_address}/32"
    destination_port_range = "22"
    protocol = "TCP"
}
resource "azure_security_group_rule" "bastion_block" {
    name = "${var.env}-bastion-block-rule"
    security_group_names = ["${azure_security_group.bastion.name}"]
    type = "Inbound"
    action = "Deny"
    priority = 999
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "${azure_instance.bastion.vip_address}/32"
    destination_port_range = "*"
    protocol = "TCP"
}

