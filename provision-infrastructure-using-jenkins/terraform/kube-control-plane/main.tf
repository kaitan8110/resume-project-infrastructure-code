terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.59.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-unique123456"
    key    = "terraform-state-controlplane"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_subnet" "controlplane_subnet_id" {
  
  filter {
    name   = "tag:Name"
    values = ["controlplane-subnet"]
  }

#   most_recent = true
}

data "aws_security_group" "controlplane_sg_id" {
  
  filter {
    name   = "tag:Name"
    values = ["controlplane_sg"]
  }

#   most_recent = true
}

data "aws_key_pair" "key_pair_id" {
  
  filter {
    name   = "tag:Name"
    values = ["resume-project-key-pair"]
  }

#   most_recent = true
}

resource "aws_network_interface" "controlplane_eni" {
  subnet_id       = data.aws_subnet.controlplane_subnet_id.id
  security_groups = [data.aws_security_group.controlplane_sg_id.id]

}

resource "aws_instance" "controlplane" {
  ami           = "ami-0497a974f8d5dcef8" # us-east-1
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = resource.aws_network_interface.controlplane_eni.id
    device_index         = 0
  }
  availability_zone = "ap-southeast-1b"
  key_name = data.aws_key_pair.key_pair_id.key_name

  tags= {
    Name = "kube-control-plane"
  }

}