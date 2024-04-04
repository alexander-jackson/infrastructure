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
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
        ]
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
