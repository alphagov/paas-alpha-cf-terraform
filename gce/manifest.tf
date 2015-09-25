resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    vars {
        gce_static_ip     =  "${google_compute_address.bosh.address}"
        gce_project_id    =  "${var.gce_project}"
        gce_default_zone  =  "${var.gce_region_zone}"
        gce_microbosh_net =  "${google_compute_network.bastion.name}"
        gce_account_json  =  "${var.gce_account_json}"
    }

    provisioner "local-exec" {
        command = "/bin/echo '${template_file.manifest.rendered}' > manifest.yml"
    }
}

