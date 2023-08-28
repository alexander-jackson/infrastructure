resource "digitalocean_project" "blackboards" {
  name        = "blackboards"
  purpose     = "Service or API"
  environment = "Production"
  is_default  = true

  resources = [
    digitalocean_droplet.postgres.urn,
  ]
}

resource "digitalocean_ssh_key" "m2" {
  name       = "m2"
  public_key = file("keys/id_rsa.pub")
}

resource "digitalocean_ssh_key" "secondary" {
  name       = "secondary"
  public_key = file("keys/secondary_id_rsa.pub")
}

resource "digitalocean_droplet" "postgres" {
  name       = "postgres"
  image      = "ubuntu-22-10-x64"
  region     = "lon1"
  size       = "s-1vcpu-1gb"
  monitoring = true
  ssh_keys   = [digitalocean_ssh_key.m2.id, digitalocean_ssh_key.secondary.id]
}
