variable "aws_user" {
  type = list(string)
  default = ["Seob"]
}

variable "instance_ami" {
  description = "Ubuntui AMI ID for eu-central-1"
  type = string
  default = ["ami for linux vdi"]
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "public_key_path" {
  type = string
  default = ".ssh/[path]"
}

variable "s3_bucket_name" {
  type = string
  default = "seob-bucket"
}

variable "aws_region" {
  description = "AWS region"
  type = string
  default = "eu-central-1"
}

---

variable "vpc_cidr" {
  description = "IP range for VPC"
  type = string
  default = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "IP range for subnet"
  type = string
  default = "10.10.10.0/24"
}

variable "availability_zone" {
  descriptiuon = "Availability zone for EC2 and EBS"
  type = string
  default = "eu-central-1a"
}
