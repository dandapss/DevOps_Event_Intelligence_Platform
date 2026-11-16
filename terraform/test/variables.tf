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
