provider "aws" {
  region     = "us-east-1"
  #key and secret for AWS account
  access_key = "AKIAZMOPB5RD3H3EUTWL"
  secret_key = "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"
}


resource "aws_instance" "web-server" {
  #ami should correspond to region image
  #image for ubuntu 18.04 must comply with availability zone
  ami               = "ami-013f17f36f8b1fefb"
  #Availability zone for EC2 instance
  availability_zone = "us-east-1c"
  #type of EC2 instance
  instance_type     = "t2.micro"
  #generated key for PuTTy access into the EC2 instance
  key_name          = "PuTTy"
  #assigned network interface
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.interface1.id
  }
  #user settings of the EC2 Linux AMI
  user_data = <<-OEF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo the web server is resting, Thank you by A. Z. > /var/www/html/index.html'
                OEF
  #tag for display in management console
  tags = {
    Name = "Apache-web-server"
  }
}

resource "aws_instance" "web-server2" {
  #ami should correspond to region image
  ami               = "ami-013f17f36f8b1fefb"
  #2 different availability zones for Load Balancer to work
  availability_zone = "us-east-1a"
  instance_type     = "t2.micro"
  #assigned network interface
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.interface3.id
  }

  #user settings of the EC2 Linux AMI
  user_data = <<-OEF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo the web server is resting, Thank you by A. Z. 2 > /var/www/html/index.html'
                OEF
  #tag for display in management console
  tags = {
    Name = "Apache-web-server2"
  }
}
#Virtual private cloud for hosting of EC2 instances
resource "aws_vpc" "vpc" {
  #cidr_block for the EC2 instances to reside in
  cidr_block = "10.0.0.0/16"
  #tag for display in management console
  tags = {
    Name = "VPC"
  }
}
#a gateway for the incomming traffic
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}
#Route table is created in order for the Gateway to route the traffic
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    #redirect all the traffic from all IPs to gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    #redirect all the ipv6 traffic from all IPs to gateway
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "table"
  }
}
#subnet within vpc cidr block for EC2 instance operations
resource "aws_subnet" "network1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/26"
  #availability zone must be the same as the one declared in EC2 instance
  availability_zone = "us-east-1c"
  tags = {
    Name = "subnet"
  }
}
#subnet within vpc cidr block for another EC2 instance operations
resource "aws_subnet" "network3" {
  vpc_id            = aws_vpc.vpc.id
  #cidr block is at the end of previous subnetworknetwork
  cidr_block        = "10.0.1.64/28"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet3"
  }
}


#security group is created in order to allow externat internet connections
#to our private networks serving the EC2 instances
resource "aws_security_group" "allow_web" {
  name        = "allow web trafic"
  description = "Allow webb inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  #a rule for allowing all the trafic from every IP to port 443
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #All IPs
    cidr_blocks = ["0.0.0.0/0"]
  }
#a rule for allowing all the trafic from every IP to port 80
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #a rule for allowing all the trafic from every IP to port 22 for SSH
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
    #this is a substitute for all protocols(-1)
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "https_ssh"
  }
}
#network interface for each EC2 instance to reside on
resource "aws_network_interface" "interface1" {
  subnet_id       = aws_subnet.network1.id
  #private IP of the EC2 instance
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_network_interface" "interface3" {
  subnet_id       = aws_subnet.network3.id
  private_ips     = ["10.0.1.78"]
  security_groups = [aws_security_group.allow_web.id]
}

#creating an elastic IP(public) associated with private IP of EC2 intance
resource "aws_eip" "elastic_ip" {
  instance                  = aws_instance.web-server.id
  network_interface         = aws_network_interface.interface1.id
  #IP of target EC2 intance
  associate_with_private_ip = "10.0.1.50"
  vpc                       = true
  #the gateway should be created first due to some race conditions
  #and continuous uptime
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
#In order to use the route table from any subnet, 
#the subnet needs to be associated with the route table
resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.network1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "assoc3" {
  subnet_id      = aws_subnet.network3.id
  route_table_id = aws_route_table.route_table.id
}