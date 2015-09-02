variable "gce_account_file" {
  description = "JSON Account Credentials file for GCE"
  default = "account.json"
}

variable "gce_project" {
  description = "GCE Project Name to create machines inside of"
  default = "root-unison-859"
}

variable "gce_region" {
  description = "GCE Region to use"
  default = "europe-west1"
}

variable "gce_region_zone" {
  description = "GCE Region to use"
  default = "europe-west1-b"
}

variable "gce_zones" {
  description = "GCE Zones to choose from"
  default = "europe-west1-b,europe-west1-c,europe-west1-d"
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

