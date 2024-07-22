terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.74.1"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-unique123456"
    key    = "terraform-state"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_subnet" "controlplane_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "controlplane_subnet"
  }
}

resource "aws_subnet" "worker_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-southeast-1c"

  tags = {
    Name = "worker_subnet"
  }
}

# Create Route Table
resource "aws_route_table" "controlplane_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = "ControlplaneRouteTable"
  }
}

resource "aws_route_table" "worker_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = "WorkerRouteTable"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "controlplane_rta" {
  subnet_id      = aws_subnet.controlplane_subnet.id
  route_table_id = aws_route_table.controlplane_rt.id
}

resource "aws_route_table_association" "worker_rta" {
  subnet_id      = aws_subnet.worker_subnet.id
  route_table_id = aws_route_table.worker_rt.id
}