terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "s3" {
    bucket = "seob-bucket"
    key = "terraform/s3.tfstate"
    region = "eu-central-1"
    encrypt = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

---

# ChatGPT Codex

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "s3" {
    bucket       = "seob-bucket"
    key          = "terraform/bootstrap.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}
