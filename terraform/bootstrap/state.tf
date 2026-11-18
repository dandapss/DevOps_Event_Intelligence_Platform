resource "aws_s3_bucket" "seob_s3" {
  bucket = "seob-bucket"
}

resource "aws_s3_bucket_versioning" "seob_s3_versioning" {
  bucket = aws_s3_bucket.seob_s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "seob_s3_encrypt" {
  bucket = aws_s3_bucket.seob_s3.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "seob_s3_public_block" {
  bucket = aws_s3_bucket.seob_s3.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Using newer way [use_lockfile = true]
# Disabled

# resource "aws_dynamodb_table" "terraform_lock" {
#  name = "terraform-lock"
#
#  billing_mode = "PAY_PER_REQUEST"
#
#  hash_key = "LockID"
#
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}

---

# ChatGPT Codex

resource "aws_s3_bucket" "seob_s3" {
  bucket = "seob-bucket"

  # 이 버킷에 Terraform state가 저장되므로 삭제를 막습니다.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "seob_s3_versioning" {
  bucket = aws_s3_bucket.seob_s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "seob_s3_encrypt" {
  bucket = aws_s3_bucket.seob_s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "seob_s3_public_block" {
  bucket = aws_s3_bucket.seob_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
