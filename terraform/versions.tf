terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  cloud {
    organization = "blackboards"

    workspaces {
      name = "infrastructure"
    }
  }
}
