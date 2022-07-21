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
  name_prefix   = "terraform-lc-example-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webservers" {
  name                 = "terraform-asg-example"
  launch_configuration = aws_launch_configuration.webservers.name
  min_size             = 1
  max_size             = 2
  availability_zones   = ["us-east-1a"]

  lifecycle {
    create_before_destroy = true
  }
}
# data "aws_ami" "amzn" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amzn-ami-*"]
#   }
# }
# resource "aws_launch_template" "webservers" {
#   name_prefix   = "webservers"
#   image_id      = data.aws_ami.amzn.image_id
#   instance_type = "t2.micro"
# }

# resource "aws_autoscaling_group" "webservers" {
#   name = "asg-sample"
#   availability_zones = ["us-east-1a"]
#   desired_capacity   = 2
#   max_size           = 3
#   min_size           = 1
#   launch_configuration = aws_launch_template.webservers.name
# }
module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  
  
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  
  
  name               = "webservers-asg"
  health_check_type  = "EC2"
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1
  }

# data "aws_ami" "amazon_linux" {
#   most_recent = true

# #   filter {
# #     name   = "name"
# #     values = ["amzn2-ami-hvm-2.0.20220406.1-x86_64-gp2"]
# #   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["137112412989"] # Canonical
# }

# resource "aws_launch_configuration" "nginxserver" {
#   name_prefix   = "nginxserver_launch_config"
#   image_id      = data.aws_ami.amazon_linux.id
#   instance_type = "t2.micro"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "nginxserver" {
#   name                 = "nginxserver_asg"
#   availability_zones = ["us-east-2a"]
#   launch_configuration = aws_launch_configuration.nginxserver.name
#   min_size             = 1
#   max_size             = 2

#   lifecycle {
#     create_before_destroy = true
#   }
# }

resource "aws_autoscaling_policy" "simple_scaling" {
  name                   = "simple_scaling_policy"
  scaling_adjustment     = 3
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 100
  autoscaling_group_name = aws_autoscaling_group.appserver.name
}

resource "aws_autoscaling_group" "appserver" {
  availability_zones        = ["us-east-2a"]
  name                      = "appserver"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 100
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.appserver.name
}

resource "aws_launch_configuration" "appserver" {
  name_prefix   = "nginxserver_launch_config"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_attachment" "webservers_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.webservers.id
  elb                    = aws_elb.webservers_loadbalancer.id
}

resource "aws_elb" "webservers_loadbalancer" {
  name               = "webservers-loadbalancer"
  availability_zones = ["us-east-2a", "us-east-2b"]


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