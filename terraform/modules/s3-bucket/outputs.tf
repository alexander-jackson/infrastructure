output "arn" {
  value = aws_s3_bucket.this.arn
}

output "name" {
  value = local.bucket_name
}
