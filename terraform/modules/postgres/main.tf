# IAM policies and roles
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = format("%s-role", var.name)
  description        = format("Role for the %s instance", var.name)
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_policy" "this" {
  name        = format("%s-policy", var.name)
  description = format("Policy for %s-role", var.name)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s", var.configuration.backup_bucket)
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.configuration.backup_bucket)
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/postgres/*", var.configuration.configuration_bucket)
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_instance_profile" "this" {
  name = format("%s-instance-profile", var.name)
  role = aws_iam_role.this.name
}

# Security groups
resource "aws_security_group" "this" {
  name        = format("%s-postgres", var.name)
  description = format("Security group for the %s Postgres instance", var.name)
  vpc_id      = var.instance.vpc_id
}

resource "aws_security_group_rule" "allow_inbound_ssh" {
  description       = "Allow inbound SSH from anywhere"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_inbound_postgres" {
  description       = "Allow inbound Postgres from anywhere"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_http" {
  description       = "Allow outbound HTTP to anywhere"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_https" {
  description       = "Allow outbound HTTPS to anywhere"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_subnet" "self" {
  id = var.instance.subnet_id
}

# Instance definition
resource "aws_instance" "this" {
  ami               = var.instance.ami
  instance_type     = var.instance.type
  key_name          = var.key_name
  subnet_id         = var.instance.subnet_id
  availability_zone = var.instance.availability_zone

  user_data = templatefile("${path.module}/templates/setup.sh", {
    major_version        = var.configuration.major_version
    configuration_bucket = var.configuration.configuration_bucket

    hba_file = templatefile("${path.module}/templates/pg_hba.conf", {
      subnet_cidr_block = data.aws_subnet.self.cidr_block
    })

    backup_script = templatefile("${path.module}/templates/backup.sh", {
      backup_bucket        = var.configuration.backup_bucket
      configuration_bucket = var.configuration.configuration_bucket
    })
  })

  vpc_security_group_ids = [aws_security_group.this.id]

  iam_instance_profile = aws_iam_instance_profile.this.name

  user_data_replace_on_change = true
}

# Storage definition
resource "aws_ebs_volume" "this" {
  availability_zone = var.instance.availability_zone
  size              = var.configuration.storage_size
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.this.id
  instance_id = aws_instance.this.id
}

resource "aws_eip" "this" {
  count = var.elastic_ip ? 1 : 0

  instance = aws_instance.this.id
  domain   = "vpc"
}
