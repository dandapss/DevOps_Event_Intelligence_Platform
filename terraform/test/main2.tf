# EC2가 사용할 독립된 네트워크
resource "aws_vpc" "seob_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "seob-vpc"
  }
}

# VPC 안에서 EC2를 배치할 subnet
resource "aws_subnet" "seob_subnet" {
  vpc_id                  = aws_vpc.seob_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# VPC를 인터넷에 연결하는 출입구
resource "aws_internet_gateway" "seob_gateway" {
  vpc_id = aws_vpc.seob_vpc.id

  tags = {
    Name = "seob-igw"
  }
}

# 인터넷 목적지로 가는 경로를 담는 표
resource "aws_route_table" "seob_route_table" {
  vpc_id = aws_vpc.seob_vpc.id

  route {
    # 목적지가 모든 IPv4 주소인 경우 IGW로 보냄
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.seob_gateway.id
  }

  tags = {
    Name = "seob-public-route-table"
  }
}

# 이 subnet이 위 route table을 실제로 사용하도록 연결
resource "aws_route_table_association" "seob_r_associate" {
  subnet_id      = aws_subnet.seob_subnet.id
  route_table_id = aws_route_table.seob_route_table.id
}

# EC2가 외부로 나가는 통신을 허용
# 인바운드 포트는 여기서 상시 공개하지 않음
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
    Name = "seob-ec2"
  }
}

# EC2가 AWS Systems Manager에 등록될 때 사용할 역할 신뢰 정책
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "seob-ec2-role"
  description        = "Role used by the EC2 instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# SSM으로 EC2에 접속·관리하려는 경우 필요한 AWS 관리 정책
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM role을 EC2에 붙일 수 있는 형태로 감싸는 profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "seob-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2에 등록할 SSH 공개키
resource "aws_key_pair" "seob_key" {
  key_name   = "seob-key"
  public_key = file(var.public_key_path)
}

# EIP를 실행할 EC2
resource "aws_instance" "seob_vm" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.seob_subnet.id
  key_name                    = aws_key_pair.seob_key.key_name
  vpc_security_group_ids      = [aws_security_group.seob_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # EC2 메타데이터에 접근할 때 토큰을 요구
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name    = "seob-eip-ec2"
    Manager = "Seob"
  }
}

# PostgreSQL 데이터를 저장할 EC2 전용 디스크
resource "aws_ebs_volume" "postgres" {
  availability_zone = aws_instance.seob_vm.availability_zone
  size              = 2
  type              = "gp3"
  encrypted         = true

  tags = {
    Name    = "seob-postgres-data"
    Purpose = "PostgreSQL data"
  }

  # Terraform이 이 데이터 디스크를 실수로 삭제하지 못하게 보호
  lifecycle {
    prevent_destroy = true
  }
}

# EBS를 EC2에 연결
resource "aws_volume_attachment" "postgres" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.postgres.id
  instance_id = aws_instance.seob_vm.id
}
