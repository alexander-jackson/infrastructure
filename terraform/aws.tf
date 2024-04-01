module "remote_state_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "terraform-remote-state"
}

module "postgres_backups_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "postgres-backups"
}

module "config_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "configuration"
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
          "iam:GetLoginProfile",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
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
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
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
      },
      {
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        Resource = aws_iam_role.iac_deployer.arn
      }
    ]
  })
}

resource "aws_iam_user" "github_actions" {
  name = "github.actions"
}

resource "aws_iam_access_key" "github_actions" {
  user    = aws_iam_user.github_actions.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "github_actions" {
  name = format("%s.policy", aws_iam_user.github_actions.name)
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
        Resource = module.postgres_backups_bucket.arn
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("%s/*", module.postgres_backups_bucket.arn)
      },
    ]
  })
}

resource "aws_iam_user" "configuration_deployer" {
  name = "configuration.deployer"
}

resource "aws_iam_access_key" "configuration_deployer" {
  user    = aws_iam_user.configuration_deployer.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "configuration_deployer" {
  name = format("%s.policy", aws_iam_user.configuration_deployer.name)
  user = aws_iam_user.configuration_deployer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = module.config_bucket.arn
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("%s/f2/config.yaml", module.config_bucket.arn)
      },
    ]
  })
}

# Virtual Private Cloud definition
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  assign_generated_ipv6_cidr_block = true
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)
  availability_zone = "eu-west-1a"

  assign_ipv6_address_on_creation = true
}

# Internet Gateway definition
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# SSH key definition
resource "aws_key_pair" "main" {
  key_name   = "macbook-m2-pro"
  public_key = file("./keys/id_rsa.pub")
}

module "secondary" {
  source = "./modules/f2-instance"
  name   = "secondary"

  instance = {
    type      = "t2.nano"
    ami       = "ami-0ab14756db2442499"
    vpc_id    = aws_vpc.main.id
    subnet_id = aws_subnet.main.id

    ipv6_address_count = 0
  }

  configuration = {
    bucket    = module.config_bucket.name
    key       = "f2/config.yaml"
    image_tag = "20231102-2034"
  }

  key_name       = aws_key_pair.main.key_name
  hosted_zone_id = aws_route53_zone.opentracker.id
}

module "database" {
  source = "./modules/postgres"
  name   = "database"

  instance = {
    type              = "t4g.nano"
    ami               = "ami-0a1b36900d715a3ad"
    vpc_id            = aws_vpc.main.id
    subnet_id         = aws_subnet.main.id
    availability_zone = "eu-west-1a"
  }

  configuration = {
    major_version        = "15"
    storage_size         = 1
    backup_bucket        = module.postgres_backups_bucket.name
    configuration_bucket = module.config_bucket.name
  }

  key_name         = aws_key_pair.main.key_name
  permitted_access = [module.secondary.security_group_id]
}

# Route table definitions
resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "gateway" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.gateway.id
}

# Route 53 definitions
resource "aws_route53_zone" "opentracker" {
  name = "opentracker.app"
}

resource "aws_route53_record" "opentracker" {
  zone_id = aws_route53_zone.opentracker.id
  name    = ""
  type    = "A"
  ttl     = 300
  records = [module.secondary.public_ip]
}

resource "aws_route53_record" "opentracker_tags" {
  zone_id = aws_route53_zone.opentracker.id
  name    = "tags"
  type    = "A"
  ttl     = 300
  records = [module.secondary.public_ip]
}

resource "aws_sns_topic" "outages" {
  name = "outages"
}

resource "aws_sns_topic_subscription" "outages" {
  topic_arn = aws_sns_topic.outages.arn
  protocol  = "email"
  endpoint  = "alexanderjackson@protonmail.com"
}

resource "aws_ecr_repository" "uptime" {
  name                 = "uptime"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_iam_user" "image_builder" {
  name = "image.builder"
}

resource "aws_iam_access_key" "image_builder" {
  user    = aws_iam_user.image_builder.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "image_builder" {
  name = format("%s.policy", aws_iam_user.image_builder.name)
  user = aws_iam_user.image_builder.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage"
        ]
        Effect   = "Allow"
        Resource = aws_ecr_repository.uptime.arn
      },
      {
        Action   = ["ecr:GetAuthorizationToken"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "uptime" {
  name               = "uptime"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

locals {
  uptime_tag = "20240331-1916"
}

resource "aws_lambda_function" "uptime" {
  function_name = "uptime"
  image_uri     = format("%s:%s", aws_ecr_repository.uptime.repository_url, local.uptime_tag)
  package_type  = "Image"

  role          = aws_iam_role.uptime.arn
  architectures = ["x86_64"]
  description   = "Monitors uptime for a given URI"

  environment {
    variables = {
      TARGET_URI = "https://opentracker.app"
    }
  }
}

data "aws_iam_policy_document" "uptime_trigger_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "uptime_trigger" {
  name               = "uptime-trigger"
  assume_role_policy = data.aws_iam_policy_document.uptime_trigger_assume_role.json
}

resource "aws_iam_policy" "uptime_trigger" {
  name        = "uptime-trigger"
  description = "Policy for uptime-trigger-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.uptime.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "uptime_trigger" {
  role       = aws_iam_role.uptime_trigger.name
  policy_arn = aws_iam_policy.uptime_trigger.arn
}

resource "aws_scheduler_schedule" "uptime" {
  name                = "uptime-trigger"
  schedule_expression = "rate(1 minutes)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.uptime.arn
    role_arn = aws_iam_role.uptime_trigger.arn
  }
}
