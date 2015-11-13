variable "env" {
  description = "Environment name"
}

variable "office_cidrs" {
  description = "CSV of CIDR addresses for our office which will be trusted"
  default     = "80.194.77.90/32,80.194.77.100/32"
}

variable "web_access_cidrs" {
  description = "CSV of CIDR addresses for which we allow web access"
  default     = "80.194.77.90/32,80.194.77.100/32"
}

variable "ssh_user" {
  description = "Username used to ssh into VMs."
  default     = "ubuntu"
}

variable "microbosh_IP" {
  description = "microbosh internal IP. Do not change. This is more of a constant than variable."
  default     = "10.0.0.6"
}

variable "jenkins_elastic" {
  description = "Elastic IP for Jenkins server which will be trusted"
  default     = "52.17.162.85/32"
}
