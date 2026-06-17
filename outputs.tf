output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.tf_load_balancer.dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.portfolio_app.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.tf_ddb.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.terraform_testing.id
}