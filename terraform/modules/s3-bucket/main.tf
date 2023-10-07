locals {
  bucket_name = var.with_random_id ? format("%s-%s", var.bucket_name, random_id.this[0].hex) : var.bucket_name
}

resource "random_id" "this" {
  count = var.with_random_id ? 1 : 0

  byte_length = 3
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}
