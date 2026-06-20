output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.portfolio_app.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.portfolio_app.repository_url
}