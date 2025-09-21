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
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "Los Cinco - EC2 App Server"
  }
}
