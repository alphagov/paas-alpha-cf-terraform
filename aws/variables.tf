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

variable "public_cidrs" {
  description = "CIDR for public subnet indexed by AZ"
  default     = {
    zone0 = "10.0.0.0/24"
    zone1 = "10.0.1.0/24"
    zone2 = "10.0.2.0/24"
  }
}

variable "private_cidrs" {
  description = "CIDR for private subnet indexed by AZ"
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
  default     = "deployer-tsuru-example"
}

variable "jenkins_elastic" {
  description = "Elastic IP for Jenkins server which will be trusted"
  default     = "52.17.162.85/32"
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
  default     = "cf.paas.alphagov.co.uk."
}
