variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "bark-lab1"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "Public IPs allowed to SSH, e.g. [\"203.0.113.5/32\"]"
  type        = list(string)
}

variable "public_key_path" {
  description = "Path to your SSH public key (.pub file)"
  type        = string
  default     = "D:/HomeLab-Personal-Projects/barq-lab.pub"
}

variable "instance_type" {
  description = "EC2 instance type for both hosts"
  type        = string
  default     = "t3.micro"
}

variable "app_volume_size" {
  description = "Root volume size in GiB for the app host"
  type        = number
  default     = 10
}

variable "db_volume_size" {
  description = "Root volume size in GiB for the db host"
  type        = number
  default     = 20
}
