provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "seb-vpc" {
  cidr_block = "10.50.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "seb-vpc"
  }
}

resource "aws_internet_gateway" "seb_internet_gateway" {
  vpc_id = "${aws_vpc.seb-vpc.id}"

  tags = {
    Name = "VPC IGW"
  }
}

resource "aws_subnet" "seb-public-subnet" {
  vpc_id     = "${aws_vpc.seb-vpc.id}"
  cidr_block = "10.50.0.0/24"

  tags = {
    Name = "seb-public-subnet"
  }
}

resource "aws_subnet" "seb-private-subnet" {
  vpc_id     = "${aws_vpc.seb-vpc.id}"
  cidr_block = "10.50.1.0/24"

  tags = {
    Name = "seb-private-subnet"
  }
}

resource "aws_route_table" "seb-public-route-table" {
  vpc_id = "${aws_vpc.seb-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.seb_internet_gateway.id}"
  }

  tags = {
    Name = "Public Subnet RT"
  }
}
  resource "aws_route_table_association" "seb-public-route-table" {
    subnet_id = "${aws_subnet.seb-public-subnet.id}"
    route_table_id = "${aws_route_table.seb-public-route-table.id}"
}

resource "aws_route_table" "seb-private-route-table" {
  vpc_id = "${aws_vpc.seb-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.seb_internet_gateway.id}"
  }

  tags = {
    Name = "Private Subnet RT"
  }
}
  resource "aws_route_table_association" "seb-private-route-table" {
    subnet_id = "${aws_subnet.seb-private-subnet.id}"
    route_table_id = "${aws_route_table.seb-private-route-table.id}"
}

resource "aws_security_group" "seb-secuity-group-public" {
  name = "seb-security-group-public"
  description = "Public security group, allows HTTP/HTTPS"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  vpc_id="${aws_vpc.seb-vpc.id}"

  tags = {
    Name = "Public security group"
  }
}

resource "aws_security_group" "seb-secuity-group-private" {
  name = "seb-security-group-private"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["10.50.0.0/24"]
  }

  vpc_id="${aws_vpc.seb-vpc.id}"

  tags = {
    Name = "Private security group"
  }
}

resource "aws_key_pair" "seb-keypair" {
  key_name = "seb-keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "private_instance_seb" {
  ami = "ami-0b45d039456f24807"
  subnet_id = "${aws_subnet.seb-private-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.seb-secuity-group-private.id}"]
  instance_type = "t2.micro"
  associate_public_ip_address = false
  tags = {
    Name = "seb-app-private"
  }
}

resource "aws_instance" "public_instance_seb" {
  ami = "ami-0b45d039456f24807"
  subnet_id = "${aws_subnet.seb-public-subnet.id}"
  key_name = "${aws_key_pair.seb-keypair.id}"
  vpc_security_group_ids = ["${aws_security_group.seb-secuity-group-public.id}"]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  tags = {
    Name = "seb-app-public"
  }
}
