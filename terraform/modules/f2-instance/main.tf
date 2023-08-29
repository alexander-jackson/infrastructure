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
        Resource = var.config_arn
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = format("%s/*", var.config_arn)
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
resource "aws_security_group" "inbound_ssh" {
  name        = format("%s-inbound-ssh", var.name)
  description = "Allow inbound SSH traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_inbound_ssh" {
  description       = "Allow inbound SSH from anywhere"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.inbound_ssh.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "inbound_https" {
  name        = format("%s-inbound-https", var.name)
  description = "Allow inbound HTTPS traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_inbound_https" {
  description       = "Allow inbound HTTPS from anywhere"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.inbound_https.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "outbound_http" {
  name        = format("%s-outbound-http", var.name)
  description = "Allow outbound HTTP traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_outbound_http" {
  description       = "Allow outbound HTTP to anywhere"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.outbound_http.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "outbound_https" {
  name        = format("%s-outbound-https", var.name)
  description = "Allow outbound HTTPS traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_outbound_https" {
  description       = "Allow outbound HTTPS to anywhere"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.outbound_https.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "outbound_postgres" {
  name        = format("%s-outbound-postgres", var.name)
  description = "Allow outbound Postgres traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_outbound_postgres" {
  description       = "Allow outbound Postgres to the Digital Ocean instance"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.outbound_postgres.id
  cidr_blocks       = ["64.227.33.121/32"]
}

resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  user_data = templatefile("${path.module}/scripts/setup.sh", {
    tag = var.tag
  })

  vpc_security_group_ids = [
    aws_security_group.inbound_ssh.id,
    aws_security_group.inbound_https.id,
    aws_security_group.outbound_http.id,
    aws_security_group.outbound_https.id,
    aws_security_group.outbound_postgres.id
  ]

  iam_instance_profile = aws_iam_instance_profile.this.name

  metadata_options {
    # Since we'll be running containers, we need an extra hop
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  user_data_replace_on_change = true
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"
}
