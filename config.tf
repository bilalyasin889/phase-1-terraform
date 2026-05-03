terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  required_version = "~> 1.14.0"

  backend "s3" {
    bucket       = "bilal-phase-1-dev-tfstate"
    key          = "terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = local.default_tags
  }
}

provider "github" {
  owner = local.github_owner
}
