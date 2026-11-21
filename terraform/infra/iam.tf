### IAM ###

#------#
# Data #
#------#
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "postgresql_parameter_read" {
  statement {
    sid = "ReadPostgresSQLCredentials"
    actions = ["ssm:GetParameter"]

    resources = [
      "arn:aws:ssm:eu-central-1:236608206962:parameter/eip/prod/postgresql/admin-password",
      "arn:aws:ssm:eu-central-1:236608206962:parameter/eip/prod/postgresql/app-password"
    ]
  }
}

#----------#
# IAM Role #
#----------#

resource "aws_iam_role" "seob_role" {
  description = "Role used by the EC2 instance"
  name = "seob-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

#-------------#
# IAM Profile #
#-------------#
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "seob-ec2-profile"
  role = aws_iam_role.seob_role.name
}

#--------#
# Policy #
#--------#
resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.seob_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role = aws_iam_role.seob_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role = aws_iam_role.seob_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy" "postgresql_parameter_read" {
  name = "postgresql-parameter-read"
  role = aws_iam_role.seob_role.id
  policy = data.aws_iam_policy_document.postgresql_parameter_read.json
}
