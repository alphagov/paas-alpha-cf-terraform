output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}"
}

output "bosh_ip" {
	value = "${google_compute_address.bosh.address}"
}

output "haproxy_ip" {
        value = "${google_compute_address.haproxy.address}"
}
