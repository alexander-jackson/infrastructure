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
          "ec2:DescribeInstances",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "iam:ChangePassword",
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
    type      = "t2.nano"
    ami       = "ami-0ab14756db2442499"
    vpc_id    = aws_vpc.main.id
    subnet_id = aws_subnet.main.id
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
  count  = 0

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
