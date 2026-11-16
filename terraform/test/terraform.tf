terraform {
  backend "Seob_s3" {
    bucket = "Seob_s3_bucket"
    key = "terraform.tfstate"
    region = "eu-central-1"
}
