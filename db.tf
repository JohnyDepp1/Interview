resource "aws_instance" "DB" {
  ami           = "ami-0e0102e3ff768559b"
  instance_type = "t2.micro"
  availability_zone = "eu-central-1a"
  subnet_id = aws_subnet.network2.id
  user_data = <<-EOF
                #!/bin/bash
                yum install -y mysql56-server
              EOF
  tags = {
    Name = "DataBase"
  }
}


resource "aws_subnet" "network2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "subnet2"
  }
}

resource "aws_network_interface" "interface2" {
  subnet_id       = aws_subnet.network2.id
  private_ips     = ["10.0.2.50"]
  security_groups = [aws_security_group.allow_web.id]
}


/* resource "aws_eip" "elastic_ip" {
  instance                  = aws_instance.DB.id
  network_interface         = aws_network_interface.interface2.id
  associate_with_private_ip = "10.0.2.50"
  vpc                       = true
  depends_on = [
    aws_internet_gateway.gw
  ]
} */


resource "aws_route_table_association" "assoc2" {
  subnet_id      = aws_subnet.network2.id
  route_table_id = aws_route_table.route_table.id
}