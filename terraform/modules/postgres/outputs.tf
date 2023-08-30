output "public_ip" {
  value = aws_eip.this.public_ip
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "private_dns" {
  value = aws_instance.this.private_dns
}
