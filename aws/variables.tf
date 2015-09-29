variable "region"     {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "zones" {
  description = "AWS availability zones"
  default     = {
    zone0 = "eu-west-1a"
    zone1 = "eu-west-1b"
    zone2 = "eu-west-1c"
  }
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "infra_cidrs" {
  description = "CIDR for infrastructure subnet indexed by AZ"
  default     = {
    zone0 = "10.0.0.0/24"
    zone1 = "10.0.1.0/24"
    zone2 = "10.0.2.0/24"
  }
}

variable "cf_cidrs" {
  description = "CIDR for cf components subnet indexed by AZ"
  default     = {
    zone0 = "10.0.10.0/24"
    zone1 = "10.0.11.0/24"
    zone2 = "10.0.12.0/24"
  }
}

variable "ubuntu_amis" {
  description = "Base AMI to launch the instances with"
  default = {
    eu-west-1 = "ami-234ecc54"
    eu-central-1 = "ami-9a380b87"
  }
}

variable "key_pair_name" {
  description = "SSH Key Pair name to be used to launch EC2 instances"
  default     = "insecure-deployer"
}

variable "health_check_interval" {
  description = "Interval between requests for load balancer health checks"
  default     = 5
}

variable "health_check_timeout" {
  description = "Timeout of requests for load balancer health checks"
  default     = 2
}

variable "health_check_healthy" {
  description = "Threshold to consider load balancer healthy"
  default     = 2
}

variable "health_check_unhealthy" {
  description = "Threshold to consider load balancer unhealthy"
  default     = 2
}

variable "dns_zone_id" {
  description = "Amazon Route53 DNS zone identifier"
  default = "Z3SI0PSH6KKVH4"
}

variable "dns_zone_name" {
  description = "Amazon Route53 DNS zone name"
  default     = "cf.paas.alphagov.co.uk"
}

variable "uaadb_username" {
  description = "UAA RDS DB username"
  default     = "uaadb"
}

variable "uaadb_password" {
  description = "UAA RDS DB password"
}

variable "ccdb_username" {
  description = "Cloud Controller RDS DB username"
  default     = "ccdb"
}

variable "ccdb_password" {
  description = "Cloud Controller RDS DB password"
}

# Terraform currently only has limited support for reading environment variables
# Variables for use with terraform must be prefexed with 'TF_VAR_'
# These two variables are passed in as environment variables named:
# TF_VAR_AWS_ACCESS_KEY_ID and TF_VAR_AWS_SECRET_ACCESS_KEY respectively
variable "AWS_ACCESS_KEY_ID" {
  description = "AWS access key to be pass to the bosh CPI"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS secret access key to be pass to the bosh CPI"
}