provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "vpc-tutorial" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public-subnet-A" {
  tags {
    Name  =  "public-subnet-A"
  }
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "private-subnet-A" {
  tags {
    Name  =  "private-subnet-A"
  }
  cidr_block = "10.0.3.0/24"
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "public-subnet-B" {
  tags {
    Name  =  "public-subnet-B"
  }
  cidr_block = "10.0.2.0/24"
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
  availability_zone = "us-east-2b"
}

resource "aws_subnet" "private-subnet-B" {
  tags {
    Name  =  "private-subnet-B"
  }
  cidr_block = "10.0.4.0/24"
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
  availability_zone = "us-east-2b"
}

resource "aws_instance" "server-A" {
  ami = "ami-0bae71009e339a1e0"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private-subnet-A.id}"
  tags {
    Name = "server-A"
  }
  vpc_security_group_ids = ["${aws_security_group.web-server-and-ssh.id}"]
  #associate_public_ip_address = true
  key_name = "aws"
}

resource "aws_instance" "server-B" {
  ami = "ami-0bae71009e339a1e0"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-subnet-B.id}"
  tags {
    Name = "server-B"
  }
  vpc_security_group_ids = ["${aws_security_group.web-server-and-ssh.id}"]
  associate_public_ip_address = true
  key_name = "aws"
}

resource "aws_security_group" "web-server-and-ssh" {
  name = "web-server-and-ssh"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
}

resource "aws_security_group" "lb-security-gorup" {
  name = "load-banalcer"
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [ "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
}

resource "aws_route_table" "internet-gw-route-table" {
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet-gateway.id}"
  }
}

resource "aws_route_table_association" "internet-route-A" {
  route_table_id = "${aws_route_table.internet-gw-route-table.id}"
  subnet_id = "${aws_subnet.public-subnet-A.id}"
}

resource "aws_route_table_association" "internet-route-B" {
  route_table_id = "${aws_route_table.internet-gw-route-table.id}"
  subnet_id = "${aws_subnet.public-subnet-B.id}"
}

resource "aws_eip" "nat-elastic-ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat-elastic-ip.id}"
  subnet_id = "${aws_subnet.private-subnet-A.id}"
}

resource "aws_route_table" "nat" {
  vpc_id = "${aws_vpc.vpc-tutorial.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat.id}"
  }
}

resource "aws_route_table_association" "private-nat-A" {
  route_table_id = "${aws_route_table.nat.id}"
  subnet_id = "${aws_subnet.private-subnet-A.id}"
}
resource "aws_route_table_association" "private-nat-B" {
  route_table_id = "${aws_route_table.nat.id}"
  subnet_id = "${aws_subnet.private-subnet-B.id}"
}

resource "aws_elb" "balancer" {
  "listener" {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  subnets = ["${aws_subnet.public-subnet-A.id}","${aws_subnet.public-subnet-B.id}"]
  security_groups = ["${aws_security_group.lb-security-gorup.id}"]
  health_check {
    healthy_threshold = 2
    interval = 30
    target = "http:80/"
    timeout = 3
    unhealthy_threshold = 2
  }
}

resource "aws_elb_attachment" "balancer-A" {
  elb = "${aws_elb.balancer.id}"
  instance = "${aws_instance.server-A.id}"
}

resource "aws_elb_attachment" "balancer-B" {
  elb = "${aws_elb.balancer.id}"
  instance = "${aws_instance.server-B.id}"
}

output "server-A" {
  value = "ssh -i ~/.ssh/aws.pem ec2-user@${aws_instance.server-A.public_ip}"
}

output "server-B" {
  value = "ssh -i ~/.ssh/aws.pem ec2-user@${aws_instance.server-B.public_ip}"
}

output "elb" {
  value = "${aws_elb.balancer.dns_name}"
}