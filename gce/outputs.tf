output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}"
}

output "bosh_ip" {
	value = "${google_compute_address.bosh.address}"
}

output "environment" {
	value = "${var.env}"
}

output "zone0" {
	value = "${var.zones.zone0}"
}

output "zone1" {
	value = "${var.zones.zone1}"
}

output "region" {
	value = "${var.region}"
}

output "bosh_network_name" {
	value = "${google_compute_network.bastion.name}"
}

output "cf1_network_name" {
	value = "${google_compute_network.bastion.name}"
}

output "cf2_network_name" {
	value = "${google_compute_network.bastion.name}"
}

output "logsearch1_network_name" {
	value = "${google_compute_network.bastion.name}"
}

output "bosh_network_name" {
	value = "${google_compute_network.bastion.name}"
}

output "router_pool_name" {
	value = "${google_compute_target_pool.router.name}"
}

output "graphite_pool_name" {
	value = "${google_compute_target_pool.graphite.name}"
}

output "cf_root_domain" {
	value = "${var.env}.${var.dns_zone_name}"
}

output "dns_zone_name" {
	value = "${var.dns_zone_name}"
}

output "gce_project_id" {
	value = "${var.gce_project}"
}

output "gce_account_json" {
	value = "${file("account.json")}"
#	value = "${replace(file("account.json"), "\n", "")}"
}

output "compiled_cache_bucket_access_key_id" {
	value = "${var.GCE_INTEROPERABILITY_ACCESS_KEY_ID}"
}

output "compiled_cache_bucket_secret_access_key" {
	value = "${var.GCE_INTEROPERABILITY_SECRET_ACCESS_KEY}"
}

output "compiled_cache_bucket_host" {
	value = "${var.GCE_INTEROPERABILITY_HOST}"
}
