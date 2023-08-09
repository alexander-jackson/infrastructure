module "remote_state" {
  source      = "./modules/s3-bucket"
  bucket_name = "terraform-remote-state-m3rc9k"
}

module "postgres_backups" {
  source      = "./modules/s3-bucket"
  bucket_name = "postgres-backups-tr1pjq"
}

module "configuration_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "configuration-sfvz2s"
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

resource "aws_security_group" "ssh" {
  name        = "allow-ingress"
  description = "Allow ingress traffic to the public subnet"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "http" {
  name        = "allow-outbound-http"
  description = "Allow outbound HTTP traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "https" {
  name        = "allow-outbound-https"
  description = "Allow outbound HTTPS traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_inbound_ssh" {
  description       = "Allow inbound SSH from anywhere"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ssh.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ephemeral_ssh_return" {
  description       = "Allow ephemeral SSH traffic return"
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.ssh.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_http" {
  description       = "Allow outbound HTTP traffic"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.http.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_http_return" {
  description       = "Allow outbound HTTP return traffic"
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.http.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_https" {
  description       = "Allow outbound HTTPS traffic"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.https.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_https_return" {
  description       = "Allow outbound HTTPS return traffic"
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.https.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# SSH key definition
resource "aws_key_pair" "main" {
  key_name   = "macbook-m2-pro"
  public_key = file("./keys/id_rsa.pub")
}

# EC2 Instance definition
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_primary" {
  name               = "ec2-primary"
  description        = "Role for the primary EC2 instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_policy" "ec2_primary" {
  name        = "ec2-primary-policy"
  description = "Policy for the primary EC2 instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = module.configuration_bucket.arn
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = format("%s/*", module.configuration_bucket.arn)
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_primary" {
  role       = aws_iam_role.ec2_primary.name
  policy_arn = aws_iam_policy.ec2_primary.arn
}

resource "aws_iam_instance_profile" "ec2_primary" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_primary.name
}

resource "aws_instance" "primary" {
  ami           = "ami-0ab14756db2442499"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.main.id

  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id,
    aws_security_group.https.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_primary.name

  metadata_options {
    # Since we're running a container here, we need an extra hop
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }
}

# Elastic IP definition
resource "aws_eip" "primary" {
  instance = aws_instance.primary.id
  domain   = "vpc"

  depends_on = [aws_internet_gateway.main]
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
