terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.32.1"
    }
  }

  backend "s3" {
    bucket       = "terraform-remote-state-5af08d"
    key          = "state.json"
    region       = "eu-west-1"
    use_lockfile = true
  }
}
