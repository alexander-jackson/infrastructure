resource "random_id" "this" {
  byte_length = 3
}

locals {
  bucket_name = format("%s-%s", var.bucket_name, random_id.this.hex)
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

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.pending_deletion ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "delete-files"
    status = "Enabled"

    expiration {
      days = 1
    }
  }

  rule {
    id     = "delete-versioned-files"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}
