#-----#
# EC2 #
#-----#
resource "aws_instance" "seob_vm" {
  ami = var.instance_ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.seob_subnet.id
  key_name = aws_key_pair.seob_key.key_name
  vpc_security_group_ids = [aws_security_group.seob_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

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
  bucket = var.s3_bucket_name
}

#-----#
# VPC #
#-----#
resource "aws_vpc" "seob_vpc" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "seob-vpc"
  }
}

#--------#
# Subnet #
#--------#
resource "aws_subnet" "seob_subnet" {
  vpc_id = aws_vpc.seob_vpc.id
  cidr_block = "10.10.10.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
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
}

#-------#
# Route #
#-------#
resource "aws_route" "seob_route" {
  route_table_id = aws_route_table.seob_route_table.id
  destination_cidr_block = "0.0.0.0/0"
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

#----------#
# Key Pair #
#----------#
resource "aws_key_pair" "seob_key" {
  key_name = "seob-key"
# Need the public the public directory
  public_key = file(var.public_key_path)
}

#-----#
# IAM #
#-----#
resource "aws_iam_user" "users" {
  count = length(var.aws_user)
  name = var.aws_user[count.index]
}

#######
# NEW #
#######

resource "aws_iam_role" "ec2_role" {
  description = "IAM role for cloud watch"
  name = "seob-ec2-role"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ec2_role.name

  policy_arn = "What Here?"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "seob-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_s3_bucket_versioning" "seob_s3_versioning" {
  bucket = aws_s3_bucket.seob_s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "seob_s3_encrypt" {
  bucket = aws_s3_bucket.seob_s3.id

  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "seob_s3_public_block" {
  bucket = aws_s3_bucket.seob_s3.id

  block_public_acls = true
  block_public_policy= true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-lock"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_cloudtrail" "seob_cloudtrail" {
  name = "seob-cloudtrail"

  s3_bucket_name = aws_s3_bucket.seob_s3.id

  depends_on = [aws_s3_bucket.seob_s3]
}

