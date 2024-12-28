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

module "personal" {
  source = "./modules/user"

  name = "alex.jackson"
  key  = "master.key"
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
          format("%s/f2/*.yaml", module.config_bucket.arn),
          format("%s/vector/vector.yaml", module.config_bucket.arn),
        ]
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
    image_tag = "20241103-1822"
  }

  logging = {
    bucket     = module.logging_bucket.name
    vector_tag = "0.42.0-alpine"
  }

  backups = {
    bucket = module.postgres_backups_bucket.name
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
