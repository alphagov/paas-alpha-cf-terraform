resource "azure_storage_service" "cf-storage" {
    name = "${var.env}cfstorage"
    location = "West Europe"
    description = "Default storage for CF installation"
    account_type = "Standard_LRS"
}
