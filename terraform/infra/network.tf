### Terraform Network ###

#-----#
# VPC #
#-----#
resource "aws_vpc" "seob_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "seob-vpc"
  }
}

#--------#
# Subnet #
#--------#
resource "aws_subnet" "seob_subnet" {
  vpc_id                  = aws_vpc.seob_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "seob-subnet"
  }
}

#------------------#
# Internet Gateway #
#------------------#
resource "aws_internet_gateway" "seob_gateway" {
  vpc_id = aws_vpc.seob_vpc.id

  tags = {
    Name = "seob-igw"
  }
}

#-------------#
# Route Table #
#-------------#
resource "aws_route_table" "seob_route_table" {
  vpc_id = aws_vpc.seob_vpc.id

  tags = {
    Name = "seob-route-table"
  }
}

#-------#
# Route #
#-------#
resource "aws_route" "seob_route" {
  route_table_id         = aws_route_table.seob_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.seob_gateway.id
}

#-------------------#
# Route Association #
#-------------------#
resource "aws_route_table_association" "seob_r_associate" {
  subnet_id      = aws_subnet.seob_subnet.id
  route_table_id = aws_route_table.seob_route_table.id
}

#----------------#
# Security Group #
#----------------#
resource "aws_security_group" "seob_sg" {
  name        = "seob-ec2"
  description = "Outbound access for the EIP EC2 instance"
  vpc_id      = aws_vpc.seob_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "seob-sg"
  }
}
