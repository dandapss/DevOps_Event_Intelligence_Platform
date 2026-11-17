output "instance_public_ip" {
  description = "Ansible inventory에서 사용할 EC2 공인 IP"
  value       = aws_instance.seob_vm.public_ip
}

output "security_group_id" {
  description = "배포 중 임시 SSH 규칙을 적용할 보안 그룹 ID"
  value       = aws_security_group.seob_sg.id
}

output "postgres_volume_id" {
  description = "PostgreSQL용 EBS ID"
  value       = aws_ebs_volume.postgres.id
}
