variable "aws_user" {
  type = list(string)
  default = ["Seob"]
}

variable "instance_ami" {
  type = string
  default = ["ami for linux vdi"]
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "public_key_path" {
  type = string
  default = ".ssh/[path]"
}

variable "s3_bucket_name" {
  type = string
  default = "seob-bucket"
}
