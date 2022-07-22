resource "aws_vpc" "nodejs-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "Demo nodejsvpc"
  }
}
resource "aws_internet_gateway" "nodejs-igw" {
  vpc_id = aws_vpc.nodejs-vpc.id
}
resource "aws_subnet" "nodejs-subnet" {
  vpc_id                  = aws_vpc.nodejs-vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Nodejs subnet"
  }
}

resource "aws_subnet" "nodejs-subnet1" {
  vpc_id                  = aws_vpc.nodejs-vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Nodejs subnet 1"
  }
}

#Creating Route Table
resource "aws_route_table" "nodejs-route" {
  vpc_id = aws_vpc.nodejs-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nodejs-igw.id
  }
  tags = {
    Name = "Route to internet"
  }
}
resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.nodejs-subnet.id
  route_table_id = aws_route_table.nodejs-route.id
}
resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.nodejs-subnet1.id
  route_table_id = aws_route_table.nodejs-route.id
}
# Creating Security Group for ELB
resource "aws_security_group" "nodejs-sg1" {
  name        = "nodejs Security Group"
  description = "nodejs Module"
  vpc_id      = aws_vpc.nodejs-vpc.id
  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_launch_configuration" "webservers" {
  name_prefix                 = "terraform-lc-example-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.nodejs-sg1.id}"]
    associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webservers" {
  name                 = "terraform-asg-example"
  launch_configuration = aws_launch_configuration.webservers.name
  min_size             = 1
  max_size             = 2

  vpc_zone_identifier  = [
    "${aws_subnet.nodejs-subnet.id}",
    "${aws_subnet.nodejs-subnet.id}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}
module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"


  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"


  name               = "webservers-asg"
  health_check_type  = "EC2"
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1

  vpc_zone_identifier  = [
    "${aws_subnet.nodejs-subnet.id}",
    "${aws_subnet.nodejs-subnet1.id}"
  ]
}

resource "aws_autoscaling_policy" "simple_scaling" {
  name                   = "simple_scaling_policy"
  scaling_adjustment     = 3
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 100
  autoscaling_group_name = aws_autoscaling_group.webservers.name
}
resource "aws_autoscaling_attachment" "webservers_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.webservers.id
  elb                    = aws_elb.webservers_loadbalancer.id
}

resource "aws_elb" "webservers_loadbalancer" {
  name               = "webservers-loadbalancer"
  security_groups = [
    "${aws_security_group.nodejs-sg1.id}"
  ]
  subnets = [
    "${aws_subnet.nodejs-subnet.id}",
    "${aws_subnet.nodejs-subnet1.id}"
  ]



  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

}
