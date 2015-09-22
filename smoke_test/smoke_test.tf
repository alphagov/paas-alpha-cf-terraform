variable "domain" {}
variable "env" {}

resource "template_file" "smoke_test_json" {
    filename = "${path.module}/smoke_test.json.erb"

    vars {
        noop = "do nothing, we render with erb in local provisioner"
    }

    provisioner "local-exec" {
        command = "(echo '<% env=\"${var.env}\"; domain=\"${var.domain}\" %>' && cat ${path.module}/smoke_test.json.erb) | erb > smoke_test_${var.env}.json"
    }
}

output "script_path" {
    value = "${path.module}/smoke_test.sh"
}
