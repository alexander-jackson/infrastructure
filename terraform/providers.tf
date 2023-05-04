provider "digitalocean" {
  token = var.do_token
}

provider "aws" {
  region = "eu-west-1"
}

variable "do_token" {
  type = string
}
