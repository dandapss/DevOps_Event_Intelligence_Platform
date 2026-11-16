resource "iam_user" "users" {
  count = length(var.aws_user)

  name = var.aws_user[count.index]
}
