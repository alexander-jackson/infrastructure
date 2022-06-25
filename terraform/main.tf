provider "digitalocean" {
  token = var.do_token
}

provider "aws" {
  region = "eu-west-1"
}

variable "do_token" {
  type = string
}

resource "digitalocean_project" "blackboards" {
  name        = "blackboards"
  purpose     = "Service or API"
  environment = "Production"
  resources = [
    digitalocean_domain.blackboards.urn,
    digitalocean_domain.opentracker.urn,
    digitalocean_droplet.main.urn,
  ]
}

resource "aws_key_pair" "personal" {
  key_name   = "personal_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCnjs+8WBDH0q3XAllLFVOySC1u6ezgdg0pi3E7kTh3VrXPsdh3MtyL5qDRRYSOsfyUcwlF9wlELDsGN81N3zjIjAff31pt2UlxK3DM/aKNKxCg1OTrrA5QIuobEI8I/gUHRAd+e7dXM3JQTXn+E6l14rsmjG0xwgHhdEL/FqA9qAVbW1FVbS8ULddtP8Wep2kZknqzhKoM+Bdu+lG/yxk5MPutPmCQve1g7uWubJ3aRUdNj4Xp0S8iEWBqGEdfte2PSCxON516jp6bm0lcUtYjk4r+c3QDv7/shJr8gL/dqKnmDzj7QBj/FBC10+74HAtrC0L61fl9TFCBpYVOyWAQUxSsH3K1RlTr2XEZ9tg95Wrzy6CMGpmyIMfBJwmLmFiMF7g1F0z7iSF6Ktx6um4AGeDHsfw6sNJemVr3EYh2RnGcBSAOK6uhZGO/ybxeS8YG1+VWnZXSlILZ4lPoCVatCvK43CNMYtMkLhcQc2see6lRxklCdaLLD4WllCuWOLbRg1ETedbkGVI6Ei7hFuIhyoDUKcb/8ldjtuwtrMueCaxVJAHAmOYdn03XXmeCQcI5C6hYkDQyRzrjDN9eA1eewx//mGyyDPjQGYQnCRM3S++Tpwws6J3mjd3kQznMSl2yeV9T2x0WdrzBfGAWExbrTF2FAEQhvEMmrlHhRh3Cvw== alexander@MacbookPro.local"
}

resource "aws_instance" "main" {
  ami           = "ami-0a6b5206d1730bdce"
  instance_type = "t4g.medium"

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 10
    volume_type = "gp2"
  }

  key_name = aws_key_pair.personal.key_name
}

resource "digitalocean_droplet" "main" {
  name       = "main"
  image      = "63663980"
  region     = "lon1"
  size       = "s-2vcpu-4gb"
  monitoring = true
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

resource "digitalocean_record" "root" {
  domain = digitalocean_domain.blackboards.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.main.ipv4_address
}

resource "digitalocean_record" "opentracker-root" {
  domain = digitalocean_domain.opentracker.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.main.ipv4_address
}

resource "digitalocean_record" "opentracker" {
  domain = digitalocean_domain.blackboards.id
  type   = "A"
  name   = "tracker"
  value  = digitalocean_droplet.main.ipv4_address
}

resource "digitalocean_record" "starling-listener" {
  domain = digitalocean_domain.blackboards.id
  type   = "A"
  name   = "sb-webhooks"
  value  = digitalocean_droplet.main.ipv4_address
}

resource "digitalocean_record" "starling-webhooks" {
  domain = digitalocean_domain.blackboards.id
  type   = "A"
  name   = "starling-webhooks"
  value  = digitalocean_droplet.main.ipv4_address
}
