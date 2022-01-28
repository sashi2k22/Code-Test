# Web - Application Load Balancer
resource "aws_lb" "web_lb" {
  name = "web-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.web_alb_http.id]
  subnets = [for value in aws_subnet.public_subnet: value.id]
}

# Web - ALB Security Group
resource "aws_security_group" "web_alb_http" {
  name        = "web_alb-security-group"
  description = "Allowing HTTP requests to the web load balancer"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-alb-security-group"
  }
}


# Web - Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}

# Web - Target Group
resource "aws_lb_target_group" "web_target_group" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}


# Web - EC2 Instance Security Group
resource "aws_security_group" "web_instance_sg" {
  name        = "web-server-security-group"
  description = "Allowing requests to the web servers"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.web_alb_http.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-security-group"
  }
}

data "aws_ami" "latest-ubuntuami" {
  owners = ["self"]
  most_recent   = true
  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

# Web - Launch Template
resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "web-launch-template"
  image_id      = data.aws_ami.latest-ubuntu
  instance_type = "t2.micro"
  lifecycle {
    create_before_destroy   = true
  }
}

# Web - Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name = aws_launch_template.web_launch_template.id
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  target_group_arns = [aws_lb_target_group.web_target_group.arn]
  vpc_zone_identifier = [for value in aws_subnet.public_subnet: value.id]

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy   = true
  }
}

resource "aws_autoscaling_policy" "web_asg_scale_out" {
  name                   = "${aws_launch_template.app_launch_template.name}-cpu-scale-out"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = "1"
  cooldown               = "300"
}

resource "aws_cloudwatch_metric_alarm" "web_asg_scale_out" {
  alarm_name          = "Web Server CPU utilization high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "This metric monitors ec2 high cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.web_asg_scale_out.arn]
}

resource "aws_autoscaling_policy" "web_asg_scale_in" {
  name                   = "${aws_launch_template.app_launch_template.name}-cpu-scale-in"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = "-1"
  cooldown               = "300"
}

resource "aws_cloudwatch_metric_alarm" "web_asg_scale_in" {
  alarm_name          = "Web Server CPU utilization low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "This metric monitors ec2 low cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.web_asg_scale_in.arn]
}