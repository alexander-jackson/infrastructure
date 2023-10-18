module "remote_state_bucket" {
  source         = "./modules/s3-bucket"
  bucket_name    = "terraform-remote-state"
  with_random_id = true
}

module "postgres_backups_bucket" {
  source         = "./modules/s3-bucket"
  bucket_name    = "postgres-backups"
  with_random_id = true
}

module "config_bucket" {
  source         = "./modules/s3-bucket"
  bucket_name    = "configuration"
  with_random_id = true
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
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
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

module "primary" {
  source = "./modules/f2-instance"

  name          = "primary"
  tag           = "20231007-1914"
  config_arn    = module.config_bucket.arn
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.main.id
  ami           = "ami-0ab14756db2442499"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.main.key_name
  config_bucket = module.config_bucket.name
  config_key    = "f2/config.yaml"
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
  records = [module.primary.public_ip]
}
