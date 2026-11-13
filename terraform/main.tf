resource "aws_instance" "my_vm" {
  ami = var.instance_ami
  instance_type = var.instance_type
  tags = {
    Manager = "Seob"
  }

}
