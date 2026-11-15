output "instance_id" {
  description = "ec2 instance id for Ansible"
  value = aws_instance.eip.id
}

output "instance_public_ip" {
  description = "new ec2 public ip for ansible inventory"
  value = aws_instance.eip.public_ip
}

output "security_group_id" {
  description = "new security group id for temporary SSH rule"
  value = aws_security_group.ec2.id
}

output "postgres_volume_id" {
  description = "EBS volume ID to store PostgreSQL data"
  value = aws_ebs_volume.postgres.id
}
