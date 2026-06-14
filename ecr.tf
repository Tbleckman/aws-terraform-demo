resource "aws_ecr_repository" "portfolio_app" {
  name = "portfolio-app"
  image_scanning_configuration {
    scan_on_push = true
  }
}