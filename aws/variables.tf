variable "region"     {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "zones" {
  description = "AWS availability zone"
  default     = {
    zone0 = "eu-west-1a"
  }
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "public_cidrs" {
  description = "CIDR for public subnet indexed by AZ"
  default     = {
    zone0 = "10.0.0.0/24"
  }
}

variable "cf_cidr" {
  description = "CIDRs for cloud foundry core components"
  default     = {
    zone0 = "10.0.1.0/24"
    zone1 = "10.0.2.0/24"
  }
}

variable "apps_cidr" {
  description = "CIDRs for components used by apps: DEAs and routers"
  default     = {
    zone0 = "10.0.11.0/24"
    zone1 = "10.0.12.0/24"
  }
}

variable "amis" {
  description = "Base AMI to launch the instances with"
  default = {
    eu-west-1 = "ami-234ecc54"
    eu-central-1 = "ami-9a380b87"
  }
}

variable "key_pair_name" {
  description = "SSH Key Pair name to be used to launch EC2 instances"
  default     = "deployer-tsuru-example"
}
