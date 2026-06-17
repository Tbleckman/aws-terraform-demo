#EC2 INSTANCE / ASG CONFIGURATION
/*
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

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

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

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
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

#GIVE EC2 ROLE ECR PULL ACCESS
resource "aws_iam_role_policy_attachment" "ec2_ecr_readonly" {
  role       = aws_iam_role.ec2_ddb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
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
*/

#MONITORING SECTION FOR HIGH CPU ALARM + UNHEALTHY TARGETS
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "tf-project-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_actions             = [aws_sns_topic.cloudwatch_notification.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_notification.arn]
  insufficient_data_actions = [aws_sns_topic.cloudwatch_notification.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.portfolio_app.name
  }
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

  alarm_actions             = [aws_sns_topic.cloudwatch_notification.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_notification.arn]
  insufficient_data_actions = [aws_sns_topic.cloudwatch_notification.arn]
  dimensions = {
    TargetGroup  = aws_alb_target_group.tf_alb_target_group.arn_suffix
    LoadBalancer = aws_lb.tf_load_balancer.arn_suffix
  }
}

resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.portfolio_app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_tracking" {
  name               = "ecs-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 60
    scale_in_cooldown  = 300
    scale_out_cooldown = 120

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

#LOGGING SECTION FOR WEBSITE
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/portfolio-app"
  retention_in_days = 14 #so it doesnt last forever...
}

/*
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
*/

#SNS TOPIC
resource "aws_sns_topic" "cloudwatch_notification" {
  name = "tf-cloudwatch-notification"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.cloudwatch_notification.arn
  protocol  = "email"
  endpoint  = "thomasbleckman@gmail.com"
}


#CLOUDWATCH DASHBOARD
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "asg-performance-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.portfolio_app.name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.portfolio_app.name, { "yAxis" : "right" }],
            ["AWS/ECS", "RunningTaskCount", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.portfolio_app.name]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ECS Fargate Core Metrics (CPU, Memory & Task Count)"
          yAxis = {
            left  = { min = 0, label = "Percent / Count" }
            right = { min = 0, label = "Memory Percent" }
          }
        }
      }
    ]
  })
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

/*
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
*/