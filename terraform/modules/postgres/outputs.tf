output "security_group_id" {
  value = aws_security_group.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}
