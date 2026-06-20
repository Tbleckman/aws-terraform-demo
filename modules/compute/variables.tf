variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "alb_sg_id" {}
variable "target_group_arn" {}
variable "dynamodb_table_arn" {}

variable "app_name" {
  type = string
}
variable "ecs_cpu" {
  type = number
}
variable "ecs_memory" {
  type = number
}
variable "ecs_desired_count" {
  type = number
}
variable "aws_region" {
  type = string
}