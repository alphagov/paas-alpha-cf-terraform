variable "gce_project" {
  description = "GCE Project Name to create machines inside of"
  default = "root-unison-859"
}

variable "region" {
  description = "GCE Region to use"
  default = "europe-west1"
}

variable "gce_region_zone" {
  description = "GCE Region to use"
  default = "europe-west1-b"
}

variable "zones" {
  description = "GCE availability zones"
  default     = {
    zone0 = "europe-west1-b"
    zone1 = "europe-west1-c"
    zone2 = "europe-west1-d"
  }
}

variable "ssh_key_path" {
  description = "Path to the ssh key to use"
  default = "ssh/insecure-deployer.pub"
}

variable "user" {
  description = "User account to set up SSH keys for"
  default = "ubuntu"
}

variable "os_image" {
  description = "OS image to boot VMs using"
  default = "ubuntu-1404-trusty-v20150316"
}

variable "bastion_cidr" {
  description = "CIDR for bastion network"
  default = "10.0.0.0/24"
}

variable "gce_account_json" {
  describe    = "To be replaced with actual contents of account.json at runtime."
  default     = "changeme"
}

variable "dns_zone_id" {
  description = "Google DNS zone identifier"
  default     = "cf2"
}

variable "dns_zone_name" {
  description = "Google DNS zone name"
  default     = "cf2.paas.alphagov.co.uk"
}

# Terraform currently only has limited support for reading environment variables
# Variables for use with terraform must be prefexed with 'TF_VAR_'
# These two variables are passed in as environment variables named:
# TF_VAR_GCE_INTEROPERABILITY_ACCESS_KEY_ID and
# TF_VAR_GCE_INTEROPERABILITY_SECRET_ACCESS_KEY respectively
variable "GCE_INTEROPERABILITY_ACCESS_KEY_ID" {
  description = "GCE interoperability access key to be pass to access buckets"
}

variable "GCE_INTEROPERABILITY_SECRET_ACCESS_KEY" {
  description = "GCE interoperability secret access key to be pass to access buckets"
}

variable "GCE_INTEROPERABILITY_HOST" {
  description = "GCE interoperability host to access buckets"
  default = "storage.googleapis.com"
}

