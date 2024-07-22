terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.74.1"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-unique123456"
    key    = "terraform-state-ansible"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# module "s3-bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "2.6.0"
#   bucket= var.ansible_bucket

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
#   force_destroy = true

#   lifecycle {
#     ignore_changes = [
#       server_side_encryption_configuration,
#     ]
#   }
# }

resource "aws_s3_bucket" "ansible_bucket" {
  bucket = var.ansible_bucket

  tags = {
    Name        = "AnsibleBucket"
    Environment = "Dev"
  }

  lifecycle {
    ignore_changes = [
      server_side_encryption_configuration,
    ]
  }
}

resource "aws_s3_bucket_acl" "ansible_bucket_acl" {
  bucket = aws_s3_bucket.ansible_bucket.bucket
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "ansible_bucket" {
  bucket = aws_s3_bucket.ansible_bucket.bucket

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_bucket" {
  bucket = aws_s3_bucket.ansible_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_bucket" {
  bucket = aws_s3_bucket.ansible_bucket.bucket

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    filter {
      prefix = "logs/"
    }
  }
}