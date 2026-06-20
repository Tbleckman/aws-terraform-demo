# moves.tf — TEMPORARY. Delete after a clean `terraform apply`.

# ---------- database ----------
moved {
  from = aws_dynamodb_table.tf_ddb
  to   = module.database.aws_dynamodb_table.tf_ddb
}
moved {
  from = aws_vpc_endpoint.dynamodb
  to   = module.database.aws_vpc_endpoint.dynamodb
}
moved {
  from = aws_vpc_endpoint_route_table_association.dynamodb
  to   = module.database.aws_vpc_endpoint_route_table_association.dynamodb
}

# ---------- compute ----------
moved {
  from = aws_ecr_repository.portfolio_app
  to   = module.compute.aws_ecr_repository.portfolio_app
}
moved {
  from = aws_ecs_cluster.main
  to   = module.compute.aws_ecs_cluster.main
}
moved {
  from = aws_cloudwatch_log_group.ecs_app
  to   = module.compute.aws_cloudwatch_log_group.ecs_app
}
moved {
  from = aws_iam_role.ecs_task_execution_role
  to   = module.compute.aws_iam_role.ecs_task_execution_role
}
moved {
  from = aws_iam_role_policy_attachment.ecs_execution_policy
  to   = module.compute.aws_iam_role_policy_attachment.ecs_execution_policy
}
moved {
  from = aws_iam_role.ecs_task_role
  to   = module.compute.aws_iam_role.ecs_task_role
}
moved {
  from = aws_iam_role_policy.ecs_dynamodb_access_policy
  to   = module.compute.aws_iam_role_policy.ecs_dynamodb_access_policy
}
moved {
  from = aws_ecs_task_definition.portfolio_app
  to   = module.compute.aws_ecs_task_definition.portfolio_app
}
moved {
  from = aws_security_group.ecs_sg
  to   = module.compute.aws_security_group.ecs_sg
}
moved {
  from = aws_security_group_rule.ecs_allow_alb
  to   = module.compute.aws_security_group_rule.ecs_allow_alb
}
moved {
  from = aws_security_group_rule.ecs_allow_outbound
  to   = module.compute.aws_security_group_rule.ecs_allow_outbound
}
moved {
  from = aws_ecs_service.portfolio_app
  to   = module.compute.aws_ecs_service.portfolio_app
}

# ---------- monitoring ----------
moved {
  from = aws_cloudwatch_metric_alarm.high_cpu
  to   = module.monitoring.aws_cloudwatch_metric_alarm.high_cpu
}
moved {
  from = aws_cloudwatch_metric_alarm.unhealthy_targets
  to   = module.monitoring.aws_cloudwatch_metric_alarm.unhealthy_targets
}
moved {
  from = aws_cloudwatch_log_group.nginx
  to   = module.monitoring.aws_cloudwatch_log_group.nginx
}
moved {
  from = aws_sns_topic.cloudwatch_notification
  to   = module.monitoring.aws_sns_topic.cloudwatch_notification
}
moved {
  from = aws_sns_topic_subscription.email_sub
  to   = module.monitoring.aws_sns_topic_subscription.email_sub
}
moved {
  from = aws_cloudwatch_dashboard.main
  to   = module.monitoring.aws_cloudwatch_dashboard.main
}
moved {
  from = aws_appautoscaling_target.ecs_service
  to   = module.monitoring.aws_appautoscaling_target.ecs_service
}
moved {
  from = aws_appautoscaling_policy.ecs_cpu_tracking
  to   = module.monitoring.aws_appautoscaling_policy.ecs_cpu_tracking
}

# ---------- networking ----------
moved {
  from = aws_vpc.terraform_testing
  to   = module.networking.aws_vpc.terraform_testing
}
moved {
  from = aws_internet_gateway.igw
  to   = module.networking.aws_internet_gateway.igw
}
moved {
  from = aws_eip.natgwip
  to   = module.networking.aws_eip.natgwip
}
moved {
  from = aws_nat_gateway.natgw
  to   = module.networking.aws_nat_gateway.natgw
}
moved {
  from = aws_route_table.terraform_rt
  to   = module.networking.aws_route_table.terraform_rt
}
moved {
  from = aws_route_table.terraform_private_rt
  to   = module.networking.aws_route_table.terraform_private_rt
}
moved {
  from = aws_subnet.terraform_testing_public_subnet
  to   = module.networking.aws_subnet.terraform_testing_public_subnet
}
moved {
  from = aws_subnet.terraform_testing_public_subnet2
  to   = module.networking.aws_subnet.terraform_testing_public_subnet2
}
moved {
  from = aws_subnet.terraform_testing_private_subnet1
  to   = module.networking.aws_subnet.terraform_testing_private_subnet1
}
moved {
  from = aws_subnet.terraform_testing_private_subnet2
  to   = module.networking.aws_subnet.terraform_testing_private_subnet2
}
moved {
  from = aws_route_table_association.subnet_routing1
  to   = module.networking.aws_route_table_association.subnet_routing1
}
moved {
  from = aws_route_table_association.subnet_routing2
  to   = module.networking.aws_route_table_association.subnet_routing2
}
moved {
  from = aws_route_table_association.subnet_routing_private1
  to   = module.networking.aws_route_table_association.subnet_routing_private1
}
moved {
  from = aws_route_table_association.subnet_routing_private2
  to   = module.networking.aws_route_table_association.subnet_routing_private2
}

# ---------- frontend ----------
moved {
  from = aws_route53_record.root
  to   = module.frontend.aws_route53_record.root
}
moved {
  from = aws_lb.tf_load_balancer
  to   = module.frontend.aws_lb.tf_load_balancer
}
moved {
  from = aws_alb_target_group.tf_alb_target_group
  to   = module.frontend.aws_alb_target_group.tf_alb_target_group
}
moved {
  from = aws_alb_listener.https
  to   = module.frontend.aws_alb_listener.https
}
moved {
  from = aws_alb_listener.redirect_http
  to   = module.frontend.aws_alb_listener.redirect_http
}
moved {
  from = aws_security_group.tf_sg
  to   = module.frontend.aws_security_group.tf_sg
}
moved {
  from = aws_vpc_security_group_ingress_rule.allow_all_inbound_https
  to   = module.frontend.aws_vpc_security_group_ingress_rule.allow_all_inbound_https
}
moved {
  from = aws_vpc_security_group_ingress_rule.allow_all_inbound_http
  to   = module.frontend.aws_vpc_security_group_ingress_rule.allow_all_inbound_http
}
moved {
  from = aws_vpc_security_group_egress_rule.allow_all_outbound_traffic_ipv4
  to   = module.frontend.aws_vpc_security_group_egress_rule.allow_all_outbound_traffic_ipv4
}