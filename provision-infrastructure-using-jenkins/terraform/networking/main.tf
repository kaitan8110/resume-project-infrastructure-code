terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.59.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-unique123456"
    key    = "terraform-state-networking"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_subnet" "controlplane_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "controlplane-subnet"
  }
}

resource "aws_subnet" "worker_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-southeast-1c"

  tags = {
    Name = "worker-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "controlplane_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }

  tags = {
    Name = "controlplane-route-table"
  }
}

resource "aws_route_table" "worker_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }

  tags = {
    Name = "worker-route-table"
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

resource "aws_security_group" "controlplane_sg" {
  name        = "controlplane_sg"
  description = "Security group for Kubernetes control plane"
  vpc_id      = var.vpc_id

  // Control Plane Ingress Rules
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 6443
    to_port     = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2379
    to_port     = 2380
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 10250
    to_port     = 10259
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Egress Rules
  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "controlplane-sg"
  }
}

resource "aws_security_group" "worker_sg" {
  name        = "worker_sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  // Worker Node Ingress Rules
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 10250
    to_port     = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 30000
    to_port     = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Egress Rules
  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "worker-sg"
  }
}
