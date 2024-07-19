provider "aws" {
    access_key = trimspace(file("../../secrets/aws_access_key.txt"))
    secret_key = trimspace(file("../../secrets/aws_secret_access_key.txt"))
    region     = "ap-southeast-1"
}