output "bastion-vips" {
  value = "${join(",", azure_instance.bastion.*.vip_address)}"
}

output "bastion-ips" {
  value = "${join(",", azure_instance.bastion.*.ip_address)}"
}

