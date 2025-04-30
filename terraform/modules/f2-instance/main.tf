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
        Resource = format("arn:aws:s3:::%s", var.configuration.bucket)
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.configuration.bucket)
      },
      {
        Action   = ["route53:ListHostedZones", "route53:GetChange"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["route53:ChangeResourceRecordSets"]
        Effect   = "Allow"
        Resource = format("arn:aws:route53:::hostedzone/%s", var.hosted_zone_id)
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s", var.logging.bucket)
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.logging.bucket)
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.backups.bucket)
      },
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = var.alerting.topic_arn
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.hackathon.bucket)
      },
      {
        Action = ["textract:AnalyzeExpense"]
        Effect   = "Allow"
        Resource = "*"
      }
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
  name        = format("%s-f2-instance", var.name)
  description = format("Security group for the %s f2-instance", var.name)
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

resource "aws_security_group_rule" "allow_inbound_https" {
  description       = "Allow inbound HTTPS from anywhere"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_ssh" {
  description       = "Allow outbound SSH to anywhere"
  type              = "egress"
  from_port         = 22
  to_port           = 22
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

resource "aws_security_group_rule" "allow_outbound_postgres" {
  description       = "Allow outbound Postgres to the Digital Ocean instance"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["64.227.33.121/32"]
}

data "aws_subnet" "self" {
  id = var.instance.subnet_id
}

resource "aws_security_group_rule" "allow_outbound_subnet_postgres" {
  description       = "Allow outbound Postgres to the subnet"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = [data.aws_subnet.self.cidr_block]
}

resource "aws_instance" "this" {
  ami           = var.instance.ami
  instance_type = var.instance.type
  key_name      = var.key_name
  subnet_id     = var.instance.subnet_id

  user_data = templatefile("${path.module}/scripts/setup.sh", {
    tag           = var.configuration.image_tag
    config_bucket = var.configuration.bucket
    config_key    = var.configuration.key
    vector_tag    = var.logging.vector_tag
  })

  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name

  metadata_options {
    # Since we'll be running containers, we need an extra hop
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"
}
