# Not necessary
data "aws_availability_zones" "available" {
  state = "available"
}

# created
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# created
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  availability_zone = data.aws_availability_zones.avilable.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public"
  }
}

# created
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# created
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.envionment}-public"
  }
}

# created
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2"
  description = "EIP EC2 security group. SSH is opened temporarily by the deployment workflow"
  vpc_id = aws_vpc.main.id

  egress {
    description = "Outbound access for package downlaods, external APIs, and GHCR image pulls"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }
}


resource "aws_instance" "eip" {
  ami = var.instance_ami
  instance_type = var.instance_type
  key_name = var.key_name
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size_gib
    encrypted = true
    delete_on_termination = true
  }

  monitoring = false

  tags = {
    Name = "${var.proejct_name}-${var.environment}-k3s"
  }
}

resource "aws_ebs_volume" "postgres" {
  availability_zone = aws_instance.eip.availability_zone
  size = 2
  type = "gp3"
  encrypted = true

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres-data"
    Purpose = "PostgreSQL data"
  }

  lifecycle {
    prvent_destroy = true
  }
}


resource "aws_volume_attachmnet" "postgres" {
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.postgres.id
  instance_id = aws_instance.eip.id

  skip_destry = true
}

# created
resource "aws_instance" "my_vm" {
  ami = var.instance_ami
  instance_type = var.instance_type
  tags = {
    Manager = "Seob"
  }

}
