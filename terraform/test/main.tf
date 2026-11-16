#-----#
# EC2 #
#-----#
resource "aws_instance" "seob_vm" {
  ami = var.instance_ami
  instance_type = var.instance_type

  tags = {
    Manager = "Seob"
  }
}

#----#
# S3 #
#----#
resource "aws_s3_bucket" "seob_s3" {
  description = "For tfstate and DB"
  bucket = "Seob_bucket"
}

#-----#
# VPC #
#-----#
resource "aws_vpc" "seob_vpc" {
  description = "Network for my ec2"
  cidr_block = "10.10.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
}

#--------#
# Subnet #
#--------#


#------------------#
# Internet Gateway #
#------------------#

#-------------#
# Route Table #
#-------------#

#----------------#
# Security Group #
#----------------#

#-----#
# IAM #
#-----#
resource "iam_user" "users" {
  count = length(var.aws_user)
  name = var.aws_user[count.index]
}

