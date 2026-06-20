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