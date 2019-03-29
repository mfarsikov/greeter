provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "greeter-server" {
  image_id = "ami-063acf95dd32e67ea"
  instance_type = "t2.micro"
  key_name = "aws"
  security_groups = [
    "${aws_security_group.web-server-SG.name}"]
  lifecycle {
    create_before_destroy = true
  }
}

variable "server-port" {
  type = "string"
  default = 80
  description = "Web server port"
}

resource "aws_security_group" "web-server-SG" {
  name = "web-server-sec-group"

  ingress {
    from_port = "${var.server-port}"
    protocol = "tcp"
    to_port = "${var.server-port}"
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
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "greeter-asg" {
  max_size = 2
  min_size = 1
  desired_capacity = 1
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  launch_configuration = "${aws_launch_configuration.greeter-server.id}"
  load_balancers = ["${aws_elb.greeter-lb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "greeter-asg"
    propagate_at_launch = true
  }
}

resource "aws_elb" "greeter-lb" {
  name = "greeter-lb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    interval = 30
    target = "http:${var.server-port}/hello"
    timeout = 3
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "elb" {
  name = "elb"
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "lb-IP" {
  value = "${aws_elb.greeter-lb.dns_name}"
}