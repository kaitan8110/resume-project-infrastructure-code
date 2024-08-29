terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.59.0"
    }
  }
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create Jenkins Subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "jenkins-subnet"
  }
}

# Create NAT Gateway
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "main-nat-gateway"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-internet-gateway"
  }
}

# Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Create Jenkins Route Table
resource "aws_route_table" "jenkins_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "jenkins-route-table"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Jenkins Route Table with Jenkins Subnet
resource "aws_route_table_association" "jenkins_rta" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_rt.id
}

# Create Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-security-group"
  }
}

# Create Security Group for Jenkins VM
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

# Create Key Pair
resource "aws_key_pair" "resume_project_key_pair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "resume-project-key-pair"
  }
}

# Create Elastic IP
resource "aws_eip" "bastion_eip" {
  tags = {
    Name = "bastion-eip"
  }
}

# Create EC2 Instance for Bastion Host
resource "aws_instance" "bastion_host" {
  ami           = "ami-0497a974f8d5dcef8"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = var.key_name

  tags = {
    Name = "bastion-host"
  }

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  associate_public_ip_address = true

}

# Associate Elastic IP with the instance
resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion_host.id
  allocation_id = aws_eip.bastion_eip.id
}

# Create EC2 Instance
resource "aws_instance" "jenkins_vm" {
  ami           = "ami-0497a974f8d5dcef8"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.jenkins_subnet.id
  key_name      = var.key_name

  tags = {
    Name = "jenkins-vm"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  root_block_device {
    volume_size = 10   # Set the root volume size to 16 GiB
    volume_type = "gp2"
  }
}

# Output the public IP of the Bastion Host
output "bastion_host_ip" {
  value = aws_instance.bastion_host.public_ip
}

# Output the private IP of the Jenkins instance
output "jenkins_instance_private_ip" {
  value = aws_instance.jenkins_vm.private_ip
}