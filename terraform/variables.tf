# Supply this non-secret setting from the workflow environment or a local tfvars file.
# Never put AWS access keys or other credentials in Terraform variables.
variable "aws_region" {
  description = "AWS region for this project."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Short name used to tag project resources."
  type        = string
  default     = "event-intelligence"
}

variable "environment" {
  description = "deploy environment"
  type = "string"
  default = "prod"
}

variable "instance_type" {
  type = string
  default = t3.micro
}

variable "instance_ami" {
  type = string
  default = [ami_number]
  description = "ami usable to run k3s"
}

variable "key_name" {
  type = string
}

variable "vpc_cidr" {
  description = "Project VPC cidr"
  type = "string"
  default = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public Subnet cidr for ec2"
  type = string
  default = "10.20.1.0/24"
}

variable "root_volume_size_gib" {
  description = "Disk size for ec2 os"
  type = number
  default = 8

  validation {
    condition = var.root_volume_size_gib >= 8
    error_message = "root volume should be minimal 8 GB"
  }
}

variable "manager" {
  type = string
  description = "Who is managing the project?!"
  default = "Seob"
}
