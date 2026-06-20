variable "vpc_id" {}
variable "domain_name" {
  type    = string
  default = "thomasbleckmandev.com"
}
variable "public_subnet_ids" {
  type = list(string)
}
