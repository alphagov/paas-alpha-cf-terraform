resource "azure_storage_service" "cf-storage" {
    name = "${var.env}cfstorage"
    location = "West Europe"
    description = "Default storage for CF installation"
    account_type = "Standard_LRS"
}

# Fake resource to call a external command.
#
# Creates a storage account for cloudfoundry, by calling ./azure-create-storage-service.sh
#
resource "template_file" "cf-storage-account" {
  filename = "/dev/null"
  depends_on = "azure_hosted_service.cf-hosted-service"
  provisioner {
    local-exec {
        # Sadly, sleep 30 to wait for the hosted service to be created in Azure
        command = "sleep 30 && ./azure-create-storage-service.sh ${var.env}-cf-hosted-service ${var.env}cfstgaccount generated.cf-storage-account.key"
    }
  }
}


