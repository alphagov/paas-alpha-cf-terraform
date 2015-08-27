resource "template_file" "manifest" {
    filename = "${path.module}/manifest.yml.tpl"

    depends_on = "azure_hosted_service.bastion"

    vars {
      # From `azure account list`
      azure_subscription_id = "${var.azure_subscription_id}"
      azure_tenant_id = "${var.azure_tenant_id}"

      # Created by `azure-create-service-principal.sh`
      azure_client_id = "${var.azure_client_id}"
      # Password passed to the script above
      azure_client_secret = "${var.azure_client_secret}"

      # Created in terraform when setting up azure_hosted_service
      azure_resource_group_name = "${var.env}-cf-hosted-service"

      # created with azure network command (terraform network does not support assign group name)
      azure_vnet_name = "${var.env}-cf-network"
      azure_subnet_name = "${var.env}-cf-subnet"

      # Created with azure-create-storage-service.sh called from terraform.
      azure_storage_account_name = "${var.env}cfstgaccount"

      # Created with azure-create-storage-service.sh called from terraform
      # Stored in generated.cf-storage-account.key
      azure_storage_access_key = "${file("generated.cf-storage-account.key")}"

      # Output of this command. x509 request of the SSH key.
      # Needs to be created in one line
      azure_ssh_certificate = "${join("\\\\n", split("\n", file("generated.insecure-deployer.pem")))}"

      bosh_public_ip = "${replace(file("generated.bosh-public-ip"), "\n", "")}"
    }
}

resource "azure_hosted_service" "bastion" {
    name = "${var.env}-cf-bastion-service"
    location = "West Europe"
    ephemeral_contents = false
    description = "Hosted service for the CF bastion host."
    label = "${var.env}-cf-bastion-hs-01"
    provisioner "local-exec" {
        command = "./azure-upload-certificate.sh ${var.env}"
    }
}

resource "azure_instance" "bastion" {
  name = "${var.env}-cf-bastion"
  hosted_service_name = "${azure_hosted_service.bastion.name}"
  depends_on = "azure_hosted_service.bastion"
  depends_on = "azure_virtual_network.bastion"
  depends_on = "azure_storage_service.cf-storage"
  image = "Ubuntu Server 14.04 LTS"
  size = "Basic_A3"
  storage_service_name = "${var.env}cfstorage"
  location = "West Europe"
  virtual_network = "${var.env}-bastion-network"
  subnet = "${var.env}-bastion-subnet"

  username = "${var.ssh_user}"
  ssh_key_thumbprint = "${file("generated.ssh_thumbprint")}"

  endpoint {
    name = "SSH"
    protocol = "tcp"
    public_port = 22
    private_port = 22
  }

  provisioner "local-exec" {
    command = "./azure-acl-rule.sh ${var.env}-cf-bastion SSH 10 permit ${var.office_cidrs}"
  }

  provisioner "remote-exec" {
        inline = ["cat << EOF > /home/ubuntu/manifest.yml",
         "${template_file.manifest.rendered}",
         "EOF"]
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer"
          destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer.pub"
          destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file" {
      source = "${path.module}/provision.sh"
      destination = "/home/ubuntu/provision.sh"
  }
}
