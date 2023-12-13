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
  ami           = "ami-0080974613cf1e8c7"
  instance_type = "t2.micro"
}