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

module "logging_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "logging"
}

module "hackathon_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "hackathon"
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
      }
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

locals {
  forkup_dev_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/forkup-dev"
}

data "aws_caller_identity" "current" {}

module "personal" {
  source = "./modules/user"

  name = "alex.jackson"
  key  = "master.key"

  hackathon_bucket_name = module.hackathon_bucket.name
  forkup_dev_role_arn   = local.forkup_dev_role_arn
}

module "repositories" {
  source   = "./modules/repository"
  for_each = toset(["ticket-tracker"])

  name = each.key
}

resource "aws_iam_user" "github_actions" {
  name = "github.actions"
}

resource "aws_iam_access_key" "github_actions" {
  user    = aws_iam_user.github_actions.name
  pgp_key = file("keys/master.key")
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

resource "aws_iam_user" "postgres_backups" {
  name = "postgres.backups"
}

resource "aws_iam_access_key" "postgres_backups" {
  user    = aws_iam_user.postgres_backups.name
  pgp_key = file("keys/master.key")
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
  pgp_key = file("keys/master.key")
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
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = [
          format("%s/f2/config.yaml", module.config_bucket.arn),
          format("%s/f2/anchor.pem", module.config_bucket.arn),
          format("%s/forkup/config.yaml", module.config_bucket.arn),
          format("%s/vector/vector.yaml", module.config_bucket.arn),
        ]
      },
    ]
  })
}

resource "aws_iam_role" "forkup_dev" {
  name = "forkup-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = module.personal.user_arn
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "textract.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "forkup_dev_policy" {
  name        = "forkup-dev-policy"
  description = "Permissions for the forkup-dev role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s", module.hackathon_bucket.name)
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", module.hackathon_bucket.name)
      },
      {
        Action   = ["textract:AnalyzeExpense", "textract:StartExpenseAnalysis"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = aws_sns_topic.expense_analysis_completions.arn
      },
      {
        Action   = "sqs:ReceiveMessage"
        Effect   = "Allow"
        Resource = aws_sqs_queue.expense_analysis_completions.arn
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "textract.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "forkup_dev" {
  role       = aws_iam_role.forkup_dev.name
  policy_arn = aws_iam_policy.forkup_dev_policy.arn
}

# Virtual Private Cloud definition
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-1a"
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
    type      = "t2.micro"
    ami       = "ami-0ab14756db2442499"
    vpc_id    = aws_vpc.main.id
    subnet_id = aws_subnet.main.id
  }

  configuration = {
    bucket    = module.config_bucket.name
    key       = "f2/config.yaml"
    image_tag = "20250719-1110"
  }

  logging = {
    bucket     = module.logging_bucket.name
    vector_tag = "0.48.0-alpine"
  }

  backups = {
    bucket = module.postgres_backups_bucket.name
  }

  hackathon = {
    bucket = module.hackathon_bucket.name
  }

  alerting = {
    topic_arn = aws_sns_topic.outages.arn
  }

  key_name = aws_key_pair.main.key_name
  hosted_zones = [
    aws_route53_zone.opentracker.id,
    aws_route53_zone.forkup.id
  ]
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

  key_name   = aws_key_pair.main.key_name
  elastic_ip = false
}

resource "aws_security_group_rule" "allow_inbound_connections_from_secondary" {
  description              = format("Allow inbound connections from %s", module.secondary.security_group_id)
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.secondary.security_group_id
  security_group_id        = module.database.security_group_id
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

resource "aws_route53_zone" "forkup" {
  name = "forkup.app"
}

resource "aws_route53_record" "records" {
  for_each = toset([
    "", // root record
    "tags",
    "today",
    "uptime"
  ])

  zone_id = aws_route53_zone.opentracker.id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [module.secondary.public_ip]
}

resource "aws_route53_record" "forkup_records" {
  for_each = toset([
    "" // root record
  ])

  zone_id = aws_route53_zone.forkup.id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [module.secondary.public_ip]
}

# Internal Route 53 definitions
resource "aws_route53_zone" "internal" {
  name = "mesh.internal"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.internal.id
  name    = "postgres"
  type    = "A"
  ttl     = 300
  records = [module.database.private_ip]
}
