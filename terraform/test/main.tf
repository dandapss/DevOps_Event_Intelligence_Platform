#-----#
# EC2 #
#-----#
resource "aws_instance" "seob_vm" {
  ami = var.instance_ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.seob_subnet.id
  key_name = "what should I put here"
  vpc_security_group_ids = [aws_security_group.<name>.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted = true
    delete_on_termination = true
  }
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
resource "aws_subnet" "seob_subnet" {
  vpc_id = aws_vpc.seob_vpc.id
  cidr_block = "10.10.10.0/24"
}

#------------------#
# Internet Gateway #
#------------------#
resource "aws_internet_gateway" "seob_gateway" {
  vpc_id = aws_vpc.seob_vpc.id
}

#-------------#
# Route Table #
#-------------#
resource "aws_route_table" "seob_route_table" {
  vpc_id = aws_vpc.seob_vpc.id

  route {
    cidr_block = "10.10.10.0/24"
    gateway_id = aws_internet_gateway.seob_gateway.id
  }
}

#-------#
# Route #
#-------#
resource "aws_route" "seob_route" {
  route_table_id = aws_route_table.seob_route_table.id
  destination_cidr_block = "10.10.10.0/24"
  gateway_id = aws_internet_gateway.seob_gateway.id
}

#-------------------#
# Route Association #
#-------------------#
resource "aws_route_table_association" "seob_r_associate" {
  subnet_id = aws_subnet.seob_subnet.id
  route_table_id = aws_route_table.seob_route_table.id
}

#----------------#
# Security Group #
#----------------#
resource "aws_security_group" "seob_sg" {
  name = "Temp_SSH"
  description = "Only allowing egress"
  vpc_id = aws_vpc.seob_vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#-----#
# IAM #
#-----#
resource "iam_user" "users" {
  count = length(var.aws_user)
  name = var.aws_user[count.index]
}

