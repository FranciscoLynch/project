terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {}

resource "aws_instance" "web" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.micro"
}