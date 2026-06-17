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


#VPC
resource "aws_vpc" "terraform_testing" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "wsl-demo-vpc"
  }
}

#IGW AND NATGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform_testing.id
}

resource "aws_eip" "natgwip" {
  domain = "vpc"

  tags = { Name = "nat-gateway-eip" }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgwip.id
  subnet_id     = aws_subnet.terraform_testing_public_subnet.id

  tags = { Name = "natgw" }

  depends_on = [aws_internet_gateway.igw]
}

#ROUTE TABLE FOR VPC
resource "aws_route_table" "terraform_rt" {
  vpc_id = aws_vpc.terraform_testing.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "terraform_private_rt" {
  vpc_id = aws_vpc.terraform_testing.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
}

#SUBNETS

resource "aws_subnet" "terraform_testing_public_subnet" {
  vpc_id            = aws_vpc.terraform_testing.id
  availability_zone = "us-east-1a"
  cidr_block        = var.public_subnet_cidrs[0]

  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_subnet" "terraform_testing_public_subnet2" {
  vpc_id            = aws_vpc.terraform_testing.id
  availability_zone = "us-east-1b"
  cidr_block        = var.public_subnet_cidrs[1]

  tags = {
    Name = "Public-Subnet2"
  }
}

resource "aws_subnet" "terraform_testing_private_subnet1" {
  vpc_id            = aws_vpc.terraform_testing.id
  availability_zone = "us-east-1a"
  cidr_block        = var.private_subnet_cidrs[0]

  tags = {
    Name = "Private-Subnet1"
  }
}

resource "aws_subnet" "terraform_testing_private_subnet2" {
  vpc_id            = aws_vpc.terraform_testing.id
  availability_zone = "us-east-1b"
  cidr_block        = var.private_subnet_cidrs[1]

  tags = {
    Name = "Private-Subnet2"
  }
}

#ASSOCIATING PUBLIC SUBNETS WITH ROUTE TABLE

resource "aws_route_table_association" "subnet_routing1" {
  subnet_id      = aws_subnet.terraform_testing_public_subnet.id
  route_table_id = aws_route_table.terraform_rt.id
}

resource "aws_route_table_association" "subnet_routing2" {
  route_table_id = aws_route_table.terraform_rt.id
  subnet_id      = aws_subnet.terraform_testing_public_subnet2.id
}

resource "aws_route_table_association" "subnet_routing_private1" {
  route_table_id = aws_route_table.terraform_private_rt.id
  subnet_id      = aws_subnet.terraform_testing_private_subnet1.id
}

resource "aws_route_table_association" "subnet_routing_private2" {
  route_table_id = aws_route_table.terraform_private_rt.id
  subnet_id      = aws_subnet.terraform_testing_private_subnet2.id
}


#TEMP MOVE BLOCK (from the past)
moved {
  from = aws_route_table.terraform-rt
  to   = aws_route_table.terraform_rt
}