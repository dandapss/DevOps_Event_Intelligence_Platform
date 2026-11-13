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
