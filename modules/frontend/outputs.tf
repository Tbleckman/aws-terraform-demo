output "alb_sg_id" {
  value = aws_security_group.tf_sg.id
}

output "target_group_arn" {
  value = aws_alb_target_group.tf_alb_target_group.arn
}

output "alb_dns_name" {
  value = aws_lb.tf_load_balancer.dns_name
}

output "alb_arn_suffix" {
  value = aws_lb.tf_load_balancer.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_alb_target_group.tf_alb_target_group.arn_suffix
}