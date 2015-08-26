resource "azure_storage_service" "cf-storage" {
    name = "${var.env}cfstorage"
    location = "West Europe"
    description = "Default storage for CF installation"
    account_type = "Standard_LRS"
}

resource "azure_hosted_service" "cf-storage-service" {
    name = "${var.env}-cf-storage-service"
    location = "West Europe"
    ephemeral_contents = false
    description = "Hosted service for the storage of CF."
    label = "${var.env}-cf-storage-hs-01"
    provisioner "local-exec" {
        command = "./azure-create-storage-service.sh ${var.env}-cf-storage-service ${var.env}cfstgaccount generated.cf-storage-account.key"
    }
}
