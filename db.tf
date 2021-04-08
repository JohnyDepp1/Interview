resource "aws_instance" "DB" {
  ami               = "ami-013f17f36f8b1fefb"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  subnet_id         = aws_subnet.network2.id
  user_data         = <<-EOF
                #!/bin/bash
                yum install -y mysql56-server
              EOF
  tags = {
    Name = "DataBase"
  }
}

#subnet within vpc cidr block for EC2 instance operations
resource "aws_subnet" "network2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/26"
  #availability zone must be the same as the one declared in EC2 instance
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet2"
  }
}
#network interface for each EC2 instance to reside on
resource "aws_network_interface" "interface2" {
  subnet_id       = aws_subnet.network2.id
  #private IP of the EC2 instance
  private_ips     = ["10.0.2.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#In order to use the route table from any subnet, 
#the subnet needs to be associated with the route table
resource "aws_route_table_association" "assoc2" {
  subnet_id      = aws_subnet.network2.id
  route_table_id = aws_route_table.route_table.id
}