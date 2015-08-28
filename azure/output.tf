output "bastion-vips" {
  value = "${join(",", azure_instance.bastion.*.vip_address)}"
}
output "bastion-ips" {
  value = "${join(",", azure_instance.bastion.*.ip_address)}"
}
output "bastion_ip" {
  value = "${azure_instance.bastion.0.vip_address}"
}

#output "manifest" {
#  value = "${template_file.manifest.rendered}"
#}

