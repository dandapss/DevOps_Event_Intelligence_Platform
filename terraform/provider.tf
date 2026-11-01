# The provider uses the standard AWS credential chain.
# Local WSL may use an approved AWS profile; GitHub Actions should use OIDC.
# Do not add access_key or secret_key values here.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
