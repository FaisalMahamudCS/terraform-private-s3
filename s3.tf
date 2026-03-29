########################################
# S3 BUCKET (PRIVATE)
########################################
resource "aws_s3_bucket" "private_bucket" {
  bucket = "iot-backend-s3"

  tags = {
    Name        = "iot-backend-s3"
    Environment = "dev"
  }
}

########################################
# BLOCK ALL PUBLIC ACCESS 🔒
########################################
resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# ENABLE VERSIONING (GOOD PRACTICE)
########################################
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.private_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

########################################
# SERVER-SIDE ENCRYPTION (SSE-S3)
########################################
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

########################################
# IAM USER (FOR BACKEND APP)
########################################
resource "aws_iam_user" "app_user" {
  name = "iot-backend-app-user"
}

########################################
# ACCESS KEYS (⚠️ HANDLE CAREFULLY)
########################################
resource "aws_iam_access_key" "app_user_key" {
  user = aws_iam_user.app_user.name
}

########################################
# IAM POLICY (LIMITED TO THIS BUCKET)
########################################
resource "aws_iam_policy" "s3_access_policy" {
  name        = "iot-backend-s3-access-policy"
  description = "Private access to S3 bucket for backend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.private_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.private_bucket.arn
      }
    ]
  })
}

########################################
# ATTACH POLICY TO USER
########################################
resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.app_user.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

########################################
# OUTPUTS (⚠️ SENSITIVE)
########################################
output "iam_access_key_id" {
  value = aws_iam_access_key.app_user_key.id
}

output "iam_secret_access_key" {
  value     = aws_iam_access_key.app_user_key.secret
  sensitive = true
}

output "bucket_name" {
  value = aws_s3_bucket.private_bucket.bucket
}