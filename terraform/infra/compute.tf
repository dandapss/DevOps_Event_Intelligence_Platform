### Compute ###

#-----#
# EC2 #
#-----#
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }
}

resource "aws_instance" "seob_vm" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.seob_subnet.id
  vpc_security_group_ids = [ aws_security_group.seob_sg.id ]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted = true
    delete_on_termination = true
  }

  monitoring = false

  tags = {
    Manager = "Seob"
  }
}

#------------#
# Cloudtrail #
#------------#
resource "aws_cloudtrail" "seob_cloudtrail" {
  name = "seob-cloudtrail"

  s3_bucket_name = aws_s3_bucket.seob_s3.id

  depends_on = [aws_s3_bucket.seob_s3]
}
