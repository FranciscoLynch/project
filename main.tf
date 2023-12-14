terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}


resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "main-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_subnet" "subnet-main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "subnet-main"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-main.id
  route_table_id = aws_route_table.main-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-main.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  attachment {
    instance     = aws_instance.web.id
    device_index = 1
  }
}


resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.gw ]
}

resource "aws_instance" "web" {
  ami           = "ami-0080974613cf1e8c7"
  instance_type = "t2.micro"
  availability_zone = "sa-east-1a"

  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo first web server deployed > /var/www/html/index.html'
                EOF
  
  tags = {
    Name = "web-server"
  }
}