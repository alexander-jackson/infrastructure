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
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s", var.logging.bucket)
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = format("arn:aws:s3:::%s/*", var.logging.bucket)
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
  name        = format("%s-instance", var.name)
  description = format("Security group for the %s instance", var.name)
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

resource "aws_security_group_rule" "allow_inbound_dns_over_tls" {
  description       = "Allow inbound DNS over TLS from anywhere"
  type              = "ingress"
  from_port         = 853
  to_port           = 853
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

resource "aws_instance" "this" {
  ami           = var.instance.ami
  instance_type = var.instance.type
  key_name      = var.key_name
  subnet_id     = var.instance.subnet_id

  user_data = templatefile("${path.module}/scripts/setup.sh", {
    tag                 = var.configuration.image_tag
    config_bucket       = var.configuration.bucket
    config_key          = var.configuration.key
    vector_tag          = var.logging.vector_tag
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

  user_data_replace_on_change = false
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"
}
