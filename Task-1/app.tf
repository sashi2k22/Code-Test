# App - Application Load Balancer
resource "aws_lb" "app_lb" {
  name = "app-lb"
  internal = true
  load_balancer_type = "application"
  security_groups = [aws_security_group.app_alb_http.id]
  subnets = [for value in aws_subnet.private_subnet: value.id]
}

# App - ALB Security Group
resource "aws_security_group" "app_alb_http" {
  name        = "app-alb-security-group"
  description = "Allowing HTTP requests to the app tier application load balancer"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.web_instance_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-alb-security-group"
  }
}

# App - Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# App - Target Group
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}


# App - EC2 Instance Security Group
resource "aws_security_group" "app_instance_sg" {
  name        = "app-server-security-group"
  description = "Allowing requests to the app servers"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.app_alb_http.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-server-security-group"
  }
}

# App - Launch Template
resource "aws_launch_template" "app_launch_template" {
  name_prefix   = "app-launch-template"
  image_id      = data.aws_ami.latest-ubuntu
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_instance_sg.id]

  lifecycle {
    create_before_destroy   = true
  }
}

# App - Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name = aws_launch_template.app_launch_template.id
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  target_group_arns = [aws_lb_target_group.app_target_group.arn]
  vpc_zone_identifier = [for value in aws_subnet.private_subnet: value.id]

  lifecycle {
    create_before_destroy   = true
  }

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "app_asg_scale_out" {
  name                   = "${aws_launch_template.app_launch_template.name}-cpu-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = "1"
  cooldown               = "300"
}

resource "aws_cloudwatch_metric_alarm" "app_asg_scale_out" {
  alarm_name          = "App Server CPU utilization low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "This metric monitors ec2 low cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.app_asg_scale_out.arn]
}

resource "aws_autoscaling_policy" "app_asg_scale_in" {
  name                   = "${aws_launch_template.app_launch_template.name}-cpu-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = "-1"
  cooldown               = "300"
}

resource "aws_cloudwatch_metric_alarm" "app_asg_scale_in" {
  alarm_name          = "Web Server CPU utilization low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "This metric monitors ec2 low cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.app_asg_scale_in.arn]
}
