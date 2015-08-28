resource "azure_hosted_service" "cf-hosted-service" {
    name = "${var.env}-cf-hosted-service"
    location = "West Europe"
    ephemeral_contents = false
    description = "Hosted service for all the CF objects"
    label = "${var.env}-cf-hs-01"
}
