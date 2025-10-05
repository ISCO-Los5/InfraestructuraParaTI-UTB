terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.0"
    }
  }

  required_version = ">= 1.13"
}

provider "aws" {
  region = "us-east-2" # Ohio
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "app_server_sg" {
  name        = "los-cinco-sg"
  description = "Security group for Los Cinco EC2 instance"

  tags = {
    Name = "Los Cinco - EC2 SG"
  }

  # Allow SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "app_server_key" {
  key_name   = "los-cinco-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.app_server_key.key_name
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "Los Cinco - EC2 App Server"
  }
}

output "instance_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP address of the EC2 instance"
}

output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
