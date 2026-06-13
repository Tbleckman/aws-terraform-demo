#EC2 INSTANCE / ASG CONFIGURATION
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

resource "aws_launch_template" "EC2_ASG_template" {
  name_prefix   = "tf-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = base64encode(file("${path.module}/userdata/nginx.sh"))
  # ^ had to use encode since launch templates don't do it automatically unlike aws_instances
}

resource "aws_autoscaling_group" "EC2_ASG_GROUP" {
  name             = "Terraform-Project-EC2-ASG"
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = [aws_subnet.terraform_testing_private_subnet1.id, aws_subnet.terraform_testing_private_subnet2.id]
  launch_template {
    id      = aws_launch_template.EC2_ASG_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_alb_target_group.tf_alb_target_group.arn]

  #health checks
  health_check_type         = "ELB"
  health_check_grace_period = 300

  depends_on = [aws_iam_role_policy_attachment.cw_policy_attachment]

  tag {
    key                 = "Name"
    value               = "tf-app-asg-instance"
    propagate_at_launch = true
  }
}

#ADDING CLOUDWATCH AGENT POLICY TO ASG TEMPLATE
resource "aws_iam_role_policy_attachment" "cw_policy_attachment" {
  role       = aws_iam_role.ec2_ddb_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#TARGET TRACKING POLICY FOR CLOUDWATCH
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.EC2_ASG_GROUP.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}


#MONITORING SECTION FOR HIGH CPU ALARM + UNHEALTHY TARGETS
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "tf-project-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.EC2_ASG_GROUP.name }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    TargetGroup  = aws_alb_target_group.tf_alb_target_group.arn_suffix
    LoadBalancer = aws_lb.tf_load_balancer.arn_suffix
  }
}

#LOGGING SECTION FOR WEBSITE
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/portfolio/nginx"
  retention_in_days = 14 #so it doesnt last forever...
}

resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/portfolio/nginx/access"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/portfolio/nginx/error"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "cloud_init" {
  name              = "/portfolio/cloud-init"
  retention_in_days = 14
}

#Commented out old EC2 instance implementation for ASG instead
/*
resource "aws_instance" "ec2_instance1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.terraform_testing_private_subnet1.id
  tags          = { Name = "Instance1" }

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("${path.module}/userdata/nginx.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "ec2_instance2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.terraform_testing_private_subnet2.id
  tags          = { Name = "Instance2" }

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("${path.module}/userdata/nginx.sh")
  user_data_replace_on_change = true
}
*/

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.terraform_testing.id
}

resource "aws_security_group_rule" "ec2_allow_inbound" {
  security_group_id        = aws_security_group.ec2_sg.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.tf_sg.id

  protocol  = "tcp"
  to_port   = 80
  from_port = 80
}

resource "aws_security_group_rule" "ec2_allow_outbound" {
  security_group_id = aws_security_group.ec2_sg.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]

  to_port   = 0
  from_port = 0
  protocol  = "-1"
}