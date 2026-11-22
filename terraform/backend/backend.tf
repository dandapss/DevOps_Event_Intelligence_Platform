### Terraform ###

terraform {
  backend "s3" {
    bucket       = "seob-bucket"
    key          = "backend.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

