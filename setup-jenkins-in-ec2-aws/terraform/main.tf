# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MainVPC"
  }
}

# Create Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "MainSubnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainInternetGateway"
  }
}

# Create Route Table
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "10.0.2.0/24"  # controlplane_subnet
    gateway_id = "local"  # Use local routing within VPC
  }

  route {
    cidr_block = "10.0.3.0/24"  # worker_subnet
    gateway_id = "local"  # Use local routing within VPC
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "MainRouteTable"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# Create Security Group
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins_sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "JenkinsSecurityGroup"
  }
}

# Create Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "DeployerKeyPair"
  }
}

# Create Elastic IP
resource "aws_eip" "jenkins_eip" {
  tags = {
    Name = "JenkinsEIP"
  }
}

# Create EC2 Instance
resource "aws_instance" "jenkins" {
  ami           = "ami-0e97ea97a2f374e3d" # Amazon Linux 3 AMI (Example, use a valid Jenkins-compatible AMI)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main_subnet.id
  key_name      = var.key_name

  tags = {
    Name = "JenkinsServer"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y ansible2
              EOF
}

# Associate Elastic IP with the instance
resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins_eip.id
}

# Output the public IP of the instance
output "instance_ip" {
  value = aws_instance.jenkins.public_ip
}
