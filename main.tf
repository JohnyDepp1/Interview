provider "aws" {
  region     = "eu-central-1"
  access_key = "AKIAZMOPB5RD3H3EUTWL"
  secret_key = "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"
}


resource "aws_instance" "web-server" {
  #ami should correspond to region image
  ami               = "ami-0e0102e3ff768559b"
  availability_zone = "eu-central-1c"
  instance_type     = "t2.micro"
  key_name          = "ppk-pair"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.interface1.id
  }

  user_data = <<-OEF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo the web server is resting, Thank you by A. Z. > /var/www/html/index.html'
                OEF
  tags = {
    Name = "Apache-web-server2"
  }
}

resource "aws_instance" "web-server2" {
  #ami should correspond to region image
  ami               = "ami-0e0102e3ff768559b"
  availability_zone = "eu-central-1a"
  instance_type     = "t2.micro"
  //key_name          = "ppk-pair"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.interface3.id
  }

  user_data = <<-OEF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo the web server is resting, Thank you by A. Z. 2 > /var/www/html/index.html'
                OEF
  tags = {
    Name = "Apache-web-server2"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "table"
  }
}

resource "aws_subnet" "network1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/26"
  availability_zone = "eu-central-1c"
  tags = {
    Name = "subnet"
  }
}

resource "aws_subnet" "network3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.64/28"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "subnet3"
  }
}



resource "aws_security_group" "allow_web" {
  name        = "allow web trafic"
  description = "Allow webb inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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
    Name = "https_ssh"
  }
}

resource "aws_network_interface" "interface1" {
  subnet_id       = aws_subnet.network1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_network_interface" "interface3" {
  subnet_id       = aws_subnet.network3.id
  private_ips     = ["10.0.1.78"]
  security_groups = [aws_security_group.allow_web.id]
}


resource "aws_eip" "elastic_ip" {
  instance                  = aws_instance.web-server.id
  network_interface         = aws_network_interface.interface1.id
  associate_with_private_ip = "10.0.1.50"
  vpc                       = true
  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_eip" "elastic_ip2" {
  instance                  = aws_instance.web-server2.id
  network_interface         = aws_network_interface.interface3.id
  associate_with_private_ip = "10.0.1.78"
  vpc                       = true
  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.network1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "assoc3" {
  subnet_id      = aws_subnet.network3.id
  route_table_id = aws_route_table.route_table.id
}