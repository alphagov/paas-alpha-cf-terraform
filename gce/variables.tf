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
