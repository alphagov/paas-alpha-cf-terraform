resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    vars {
        gce_static_ip     =  "${google_compute_address.bosh.address}"
        gce_project_id    =  "${var.gce_project}"
        gce_default_zone  =  "${var.gce_region_zone}"
        gce_ssh_user      =  "${var.ssh_user}"
        gce_ssh_key_path  =  ".ssh/id_rsa"
        gce_microbosh_net = "${google_compute_network.bastion.name}"
    }

    provisioner "local-exec" {
        command = "echo '${template_file.manifest.rendered}' > manifest.yml"
    }
}

resource "template_file" "cf-manifest" {
    filename = "${path.module}/cf-manifest.yml.tpl"

    vars {
        static_ip       = "${google_compute_address.haproxy.address}"
        root_domain     = "${google_compute_address.haproxy.address}.xip.io"
        deployment_name = "${var.env}"
        network_name    = "${google_compute_network.bastion.name}"
        cf_release      = "210"
        protocol        = "http"
        common_password = "c1oudc0w"
    }

    provisioner "local-exec" {
        command = "echo '${template_file.cf-manifest.rendered}' > cf-manifest.yml"
    }
}

resource "template_file" "provision" {
    filename = "${path.module}/provision.sh.tpl"

    vars {
        gce_static_ip   =  "${google_compute_address.bosh.address}"
    }

    provisioner "local-exec" {
        command = "bash -c 'echo \'${template_file.provision.rendered}\' > provision.sh'"
    }
}
