output "arn" {
  value = aws_s3_bucket.this.arn
}

output "name" {
  value = var.bucket_name
}
