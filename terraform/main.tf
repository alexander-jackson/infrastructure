provider "digitalocean" {
  token = var.do_token
}

provider "aws" {
  region = "eu-west-1"
}

variable "do_token" {
  type = string
}

resource "aws_s3_bucket" "remote_state" {
  bucket = "terraform-remote-state-m3rc9k"
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
        Action   = ["s3:ListBucket", "s3:Get*"]
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

resource "digitalocean_project" "blackboards" {
  name        = "blackboards"
  purpose     = "Service or API"
  environment = "Production"
  resources = [
    digitalocean_domain.blackboards.urn,
    digitalocean_domain.opentracker.urn,
    digitalocean_droplet.secondary.urn,
  ]
}

resource "digitalocean_droplet_snapshot" "original-main-snapshot" {
  droplet_id = 196151282
  name       = "original-main-snapshot"
}

resource "digitalocean_droplet" "secondary" {
  name       = "secondary"
  image      = "ubuntu-22-10-x64"
  region     = "lon1"
  size       = "s-1vcpu-1gb"
  monitoring = true
  ssh_keys   = [23928565]
}

resource "digitalocean_domain" "blackboards" {
  name = "blackboards.pl"
}

resource "digitalocean_domain" "opentracker" {
  name = "opentracker.app"
}

resource "digitalocean_record" "ns1" {
  domain = digitalocean_domain.blackboards.id
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
}

resource "digitalocean_record" "opentracker-ns1" {
  domain = digitalocean_domain.opentracker.id
  type   = "NS"
  name   = "@"
  value  = "ns1.digitalocean.com."
}

resource "digitalocean_record" "ns2" {
  domain = digitalocean_domain.blackboards.id
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
}

resource "digitalocean_record" "opentracker-ns2" {
  domain = digitalocean_domain.opentracker.id
  type   = "NS"
  name   = "@"
  value  = "ns2.digitalocean.com."
}

resource "digitalocean_record" "ns3" {
  domain = digitalocean_domain.blackboards.id
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
}

resource "digitalocean_record" "opentracker-ns3" {
  domain = digitalocean_domain.opentracker.id
  type   = "NS"
  name   = "@"
  value  = "ns3.digitalocean.com."
}

resource "digitalocean_record" "opentracker-root" {
  domain = digitalocean_domain.opentracker.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.secondary.ipv4_address
}
