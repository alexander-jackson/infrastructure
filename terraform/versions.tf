terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "=2.34.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "=5.32.1"
    }
  }

  cloud {
    organization = "blackboards"

    workspaces {
      name = "infrastructure"
    }
  }
}
