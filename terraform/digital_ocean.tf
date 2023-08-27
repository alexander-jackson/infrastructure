resource "digitalocean_project" "blackboards" {
  name        = "blackboards"
  purpose     = "Service or API"
  environment = "Production"
  is_default  = true

  resources = [
    digitalocean_domain.blackboards.urn,
    digitalocean_domain.opentracker.urn,
    digitalocean_droplet.secondary.urn,
    digitalocean_droplet.postgres.urn,
  ]
}

resource "digitalocean_ssh_key" "m2" {
  name       = "m2"
  public_key = file("keys/id_rsa.pub")
}

resource "digitalocean_ssh_key" "tara" {
  name       = "tara"
  public_key = file("keys/tara.pub")
}

resource "digitalocean_ssh_key" "secondary" {
  name       = "secondary"
  public_key = file("keys/secondary_id_rsa.pub")
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

resource "digitalocean_droplet" "postgres" {
  name       = "postgres"
  image      = "ubuntu-22-10-x64"
  region     = "lon1"
  size       = "s-1vcpu-1gb"
  monitoring = true
  ssh_keys   = [digitalocean_ssh_key.m2.id, digitalocean_ssh_key.secondary.id]
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

resource "digitalocean_record" "opentracker-testing" {
  domain = digitalocean_domain.opentracker.id
  type   = "A"
  name   = "testing"
  value  = "63.32.120.39"
}
