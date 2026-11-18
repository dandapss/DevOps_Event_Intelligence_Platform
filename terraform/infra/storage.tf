### Storage ###

#------------#
# EBS Volume #
#------------#
resource "aws_ebs_volume" "seob_ebs" {
  availability_zone = aws_subnet.seob_subnet.availability_zone
  size = 2
  type = "gp3"
  encrypted = true
  lifecycle { prevent_destroy = true }
}

#-----------------------#
# EBS Volume Attachment #
#-----------------------#
resource "aws_volume_attachment" "seob_ebs_attachment" {
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.seob_ebs.id
  instance_id = aws_instance.seob_vm.id
  skip_destroy = true
}
