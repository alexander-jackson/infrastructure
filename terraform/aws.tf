module "remote_state" {
  source      = "./modules/s3-bucket"
  bucket_name = "terraform-remote-state-m3rc9k"
}

module "postgres_backups" {
  source      = "./modules/s3-bucket"
  bucket_name = "postgres-backups-tr1pjq"
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
        Action = [
          "s3:ListBucket",
          "s3:Get*",
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:GetPolicy",
          "iam:GetRole",
          "iam:GetPolicyVersion",
          "iam:ListAccessKeys",
          "iam:GetLoginProfile"
        ]
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

resource "aws_iam_user" "postgres_backups" {
  name = "postgres.backups"
}

resource "aws_iam_access_key" "postgres_backups" {
  user    = aws_iam_user.postgres_backups.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "postgres_backups" {
  name = format("%s.policy", aws_iam_user.postgres_backups.name)
  user = aws_iam_user.postgres_backups.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = module.postgres_backups.arn
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("%s/*", module.postgres_backups.arn)
      },
    ]
  })
}
