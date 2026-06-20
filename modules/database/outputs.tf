output "table_name" {
  value = aws_dynamodb_table.tf_ddb.name
}

output "table_arn" {
  value = aws_dynamodb_table.tf_ddb.arn
}