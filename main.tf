terraform {

  backend "s3" {
    bucket  = "thomaspb-terraform-testing-bucket-435"
    key     = "global/s3/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source               = "./modules/networking"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "frontend" {
  source = "./modules/frontend"

  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  domain_name       = var.domain_name
}

module "database" {
  source = "./modules/database"

  vpc_id                 = module.networking.vpc_id
  private_route_table_id = module.networking.private_route_table_id
}

module "compute" {
  source = "./modules/compute"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.frontend.alb_sg_id
  target_group_arn   = module.frontend.target_group_arn
  dynamodb_table_arn = module.database.table_arn

  app_name          = var.app_name
  ecs_cpu           = var.ecs_cpu
  ecs_memory        = var.ecs_memory
  ecs_desired_count = var.ecs_desired_count
  aws_region        = var.aws_region
}

module "monitoring" {
  source = "./modules/monitoring"

  ecs_cluster_name        = module.compute.ecs_cluster_name
  ecs_service_name        = module.compute.ecs_service_name
  alb_arn_suffix          = module.frontend.alb_arn_suffix
  target_group_arn_suffix = module.frontend.target_group_arn_suffix

  cpu_alarm_threshold  = var.cpu_alarm_threshold
  ecs_cpu_scale_target = var.ecs_cpu_scale_target
  aws_region           = var.aws_region
  alert_email          = var.alert_email
}

/*
resource "aws_s3_bucket" "terraform_testing_bucket" {
  bucket = "thomaspb-terraform-testing-bucket-435"
  force_destroy = false 
}
*/

/*
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_testing_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
*/

/*
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.terraform_testing_bucket.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
*/