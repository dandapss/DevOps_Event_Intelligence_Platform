output "instance_public_ip" {
  description = "new ec2 public ip for ansible inventory"
  value       = aws_instance.seob_vm.public_ip
}

output "postgres_volume_id" {
  description = "EBS ID for PostgreSQL"
  value       = aws_ebs_volume.seob_ebs.id
}

output "instance_id" {
  description = "ec2 instance id for Ansible"
  value = aws_instance.seob_vm.id
}
