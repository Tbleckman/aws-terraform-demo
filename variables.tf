variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR block for the public subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnet"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "thomasbleckmandev.com"
}

variable "app_name" {
  description = "Application name prefix for resource naming"
  type        = string
  default     = "portfolio-app"
}

variable "ecs_cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "ECS task memory in MiB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 14
}

variable "alert_email" {
  description = "Email address for CloudWatch SNS alerts"
  type        = string
  default     = "thomasbleckman@gmail.com"
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization % to trigger high-CPU alarm"
  type        = number
  default     = 80
}

variable "ecs_cpu_scale_target" {
  description = "Target CPU % for ECS autoscaling"
  type        = number
  default     = 60
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "thomaspb-terraform-testing-bucket-435"
}