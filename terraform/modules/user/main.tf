locals {
  key_path = format("keys/%s", var.key)
}

resource "aws_iam_user" "this" {
  name = var.name
}

resource "aws_iam_access_key" "this" {
  user    = aws_iam_user.this.name
  pgp_key = file(local.key_path)
}

resource "aws_iam_user_policy" "this" {
  name = format("%s.policy", aws_iam_user.this.name)
  user = aws_iam_user.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "cloudtrail:DescribeTrails",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricStream",
          "cloudwatch:ListDashboards",
          "cloudwatch:ListMetrics",
          "ec2:DescribeAddresses",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeRegions",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:ListImages",
          "iam:ChangePassword",
          "iam:GetAccountPasswordPolicy",
          "iam:GetRole",
          "iam:GetLoginProfile",
          "iam:GetPolicy",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListAttachedRolePolicies",
          "iam:ListGroups",
          "iam:ListGroupsForUser",
          "iam:ListMFADevices",
          "iam:ListPolicies",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:ListSigningCertificates",
          "iam:ListUsers",
          "lambda:GetAccountSettings",
          "lambda:GetFunction",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetPolicy",
          "lambda:ListAliases",
          "lambda:ListEventSourceMappings",
          "lambda:ListFunctions",
          "lambda:ListFunctionUrlConfigs",
          "lambda:ListProvisionedConcurrencyConfigs",
          "lambda:ListTags",
          "lambda:ListVersionsByFunction",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketNotification",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketLogging",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetIntelligentTieringConfiguration",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::logging-4acb18/*"
      },
      {
        Action = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s", var.hackathon_bucket_name)
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.hackathon_bucket_name)
      },
      {
        Action = ["textract:AnalyzeExpense"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_login_profile" "this" {
  user    = aws_iam_user.this.name
  pgp_key = file(local.key_path)
}
