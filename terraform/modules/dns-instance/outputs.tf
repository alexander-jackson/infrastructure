output "public_ip" {
  value = (
    var.elastic_ip_allocation_id != null
    ? data.aws_eip.external[0].public_ip
    : aws_eip.this[0].public_ip
  )
  description = "The public Elastic IP address of the instance"
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}
