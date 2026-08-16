variable "aws_region" {
  description = "AWS region for the disposable lab."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name prefix for lab resources."
  type        = string
  default     = "devops-incident-lab"
}

variable "vpc_cidr" {
  description = "CIDR for the lab VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "admin_cidr" {
  description = "Your current public IP as a /32. Never use 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid restricted CIDR and cannot be 0.0.0.0/0."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key used for disposable node access."
  type        = string
}

variable "instance_type" {
  description = "EC2 type for each Kubernetes node."
  type        = string
  default     = "t3.medium"
}
