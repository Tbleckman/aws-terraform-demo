terraform {

  backend "s3" {
    bucket = "thomaspb-terraform-testing-bucket-435"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
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
  region = "us-east-1"
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

resource "aws_vpc" "terraform_testing" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "wsl-demo-vpc"
  }
}


resource "aws_subnet" "terraform_testing_public_subnet" {
  vpc_id = aws_vpc.terraform_testing.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Public-Subnet"
  }
}