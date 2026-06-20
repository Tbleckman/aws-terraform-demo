output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.frontend.alb_dns_name
}

/*
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.portfolio_app.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
*/

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.database.table_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}