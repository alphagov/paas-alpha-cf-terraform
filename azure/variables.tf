variable "azure_credentials_file" {
  description = "JSON Account Credentials file for Azure"
  default = "credentials.publishsettings"
}

variable "virtual_network_cidr" {
  description = "CIDR for the virtual network"
  default     = "10.0.0.0/16"
}

variable "bastion_cidr" {
  description = "CIDR for bastion network"
  default = "10.0.0.0/24"
}

