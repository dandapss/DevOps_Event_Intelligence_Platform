terraform {
  backend "seob_s3" {
    bucket = "seob-bucket"
    key = "terraform.tfstate"
    region = "eu-central-1"
}
