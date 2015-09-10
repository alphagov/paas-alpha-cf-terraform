resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    vars {
        gce_static_ip     =  "${google_compute_address.bosh.address}"
        gce_project_id    =  "${var.gce_project}"
        gce_default_zone  =  "${var.gce_region_zone}"
        gce_ssh_user      =  "${var.ssh_user}"
        gce_ssh_key_path  =  ".ssh/id_rsa"
        gce_microbosh_net =  "${google_compute_network.bastion.name}"
        gce_account_json  =  "${var.gce_account_json}"
    }

    provisioner "local-exec" {
        command = "/bin/echo '${template_file.manifest.rendered}' > manifest.yml"
    }
}

resource "template_file" "cf-manifest" {
    filename = "${path.module}/cf210-manifest.yml.erb"

    vars {
        noop = "do nothing, we render with erb in local provisioner"
    }

    provisioner "local-exec" {
        command = "(echo '<% tf_static_ip=\"${google_compute_address.haproxy.address}\" ; tf_deployment_name=\"${var.env}\" ; tf_network_name=\"${google_compute_network.bastion.name}\" %>' && cat ${path.module}/cf210-manifest.yml.erb) | erb > cf-manifest.yml"
    }
}
