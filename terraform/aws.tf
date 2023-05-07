resource "aws_s3_bucket" "remote_state" {
  bucket = "terraform-remote-state-m3rc9k"
}

resource "aws_s3_bucket_versioning" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "iac_deployer" {
  name = "iac-deployer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.personal.arn
        }
      },
    ]
  })
}

resource "aws_iam_policy" "iac_deployer" {
  name        = "iac-deployer-policy"
  description = "Permissions assigned to the IAC Deployer role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket", "s3:Get*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iac_deployer" {
  role       = aws_iam_role.iac_deployer.name
  policy_arn = aws_iam_policy.iac_deployer.arn
}

resource "aws_iam_user" "personal" {
  name = "alex.jackson"
}

resource "aws_iam_access_key" "personal" {
  user    = aws_iam_user.personal.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "personal" {
  name = format("%s.policy", aws_iam_user.personal.name)
  user = aws_iam_user.personal.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListAllMyBuckets", "s3:ListBucket", "s3:Get*", "iam:ChangePassword"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        Resource = aws_iam_role.iac_deployer.arn
      }
    ]
  })
}

resource "aws_iam_user_login_profile" "personal" {
  user    = aws_iam_user.personal.name
  pgp_key = file("keys/pgp-b64.key")
}
