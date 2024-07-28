terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.59.0"
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
    Name        = "ansible-bucket"
    Environment = "dev"
  }

  lifecycle {
    ignore_changes = [
      server_side_encryption_configuration,
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "ansible_bucket" {
  bucket = aws_s3_bucket.ansible_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}