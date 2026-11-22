### Variables ###

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "IP range for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "IP range for subnet"
  type        = string
  default     = "10.10.10.0/24"
}

variable "availability_zone" {
  description = "Availability zone for EC2 and EBS"
  type        = string
  default     = "eu-central-1a"
}
