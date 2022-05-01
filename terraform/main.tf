provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {
  type = string
}

resource "digitalocean_project" "blackboards" {
  name        = "blackboards"
  purpose     = "Service or API"
  environment = "Production"
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

resource "digitalocean_record" "ns1" {
  domain = digitalocean_domain.blackboards.id
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

resource "digitalocean_record" "ns3" {
  domain = digitalocean_domain.blackboards.id
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
