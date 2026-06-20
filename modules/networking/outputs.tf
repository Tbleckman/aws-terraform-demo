output "vpc_id" {
  value = aws_vpc.terraform_testing.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.terraform_testing_public_subnet.id,
    aws_subnet.terraform_testing_public_subnet2.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.terraform_testing_private_subnet1.id,
    aws_subnet.terraform_testing_private_subnet2.id
  ]
}

output "private_route_table_id" {
  value = aws_route_table.terraform_private_rt.id
}