terraform {
  # Configure the AWS Provider
  # https://registry.terraform.io/providers/hashicorp/aws/latest
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.0"
    }
  }

  # Required Terraform version
  required_version = ">= 1.13"
}

# Configure the AWS Provider
provider "aws" {
  # Specify the AWS region
  region = "us-east-2" # Ohio
}

# Specify the AMI (Amazon Machine Image) to use
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami_ids
data "aws_ami" "ubuntu" {
  # Required to specify the AMI owner
  owners = ["099720109477"] # Canonical

  # Get the most recent AMI
  most_recent = true

  # Filter to get the latest Ubuntu 24.04 LTS AMI
  # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "app_server_key" {
  key_name   = "los-cinco-key"
  public_key = file("../../keys/id_rsa.pub")
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

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
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

# https://developer.hashicorp.com/terraform/cli/commands/output
output "instance_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP address of the EC2 instance"
}

