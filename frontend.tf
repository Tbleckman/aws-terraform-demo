#ROUTE 53 SETUP
data "aws_route53_zone" "main_zone" {
  name         = "thomasbleckmandev.com"
  private_zone = false
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main_zone.id
  name    = "thomasbleckmandev.com"
  type    = "A"

  alias {
    name                   = aws_lb.tf_load_balancer.dns_name
    zone_id                = aws_lb.tf_load_balancer.zone_id
    evaluate_target_health = true
  }
}



#EXISTING CERTIFICATE
data "aws_acm_certificate" "issued" {
  domain      = "thomasbleckmandev.com"
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}

#ALB
resource "aws_lb" "tf_load_balancer" {
  name               = "tf-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_sg.id]
  subnets            = [aws_subnet.terraform_testing_public_subnet.id, aws_subnet.terraform_testing_public_subnet2.id]

  internal                   = false
  enable_deletion_protection = true
  //tags = {Name = ""}
}

#ALB LISTENER AND TARGET GROUP SETUP
resource "aws_alb_target_group" "tf_alb_target_group" {
  name        = "app-instances-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.terraform_testing.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.tf_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = data.aws_acm_certificate.issued.arn
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tf_alb_target_group.arn
  }
}

resource "aws_alb_listener" "redirect_http" {
  load_balancer_arn = aws_lb.tf_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}



/* #we don't need attachments anymore now that the project has migrated to an ASG
#ATTACH EC2 INSTANCES TO TARGET GROUP
resource "aws_alb_target_group_attachment" "alb_ec2_attachments1" {
  target_group_arn = aws_alb_target_group.tf_alb_target_group.arn
  target_id        = aws_instance.ec2_instance1.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "alb_ec2_attachments2" {
  target_group_arn = aws_alb_target_group.tf_alb_target_group.arn
  target_id        = aws_instance.ec2_instance2.id
  port             = 80
}
*/

#SECURITY GROUP FOR ALB AND ITS IN/OUT RULES
resource "aws_security_group" "tf_sg" {
  name        = "alb_in_out"
  description = "Allow all HTTP(S) traffic and all outbound traffic for alb"
  vpc_id      = aws_vpc.terraform_testing.id

  tags = { Name = "alb_in/out" }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_inbound_https" {
  description = "secure HTTPS traffic"

  security_group_id = aws_security_group.tf_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"

  from_port = 443
  to_port   = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_inbound_http" {
  description = "HTTP web traffic"

  security_group_id = aws_security_group.tf_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"

  from_port = 80
  to_port   = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.tf_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}