variable "ecs_cluster_name" {
  type = string
}
variable "ecs_service_name" {
  type = string
}
variable "alb_arn_suffix" {
  type = string
}
variable "target_group_arn_suffix" {
  type = string
}
variable "cpu_alarm_threshold" {
  type = number
}
variable "ecs_cpu_scale_target" {
  type = number
}
variable "aws_region" {
  type = string
}
variable "alert_email" {
  type = string
}