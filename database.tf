#SIMPLE DDB TABLE TO STORE USER INPUTS ON WEBSITE (LINKEDIN OR EMAIL HANDLES)
#ONLY HAVING ONE ENTRY FOR LESS EXPENSIVE SCANS ON THE TABLE
resource "aws_dynamodb_table" "tf_ddb" {
  name         = "user-handles"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}

#CONNECT DDB WITH EC2 VIA GATEWAY ENDPOINT
data "aws_region" "cur" {}

data "aws_prefix_list" "dynamodb" {
  name = "com.amazonaws.${data.aws_region.cur.name}.dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.terraform_testing.id
  service_name      = "com.amazonaws.${data.aws_region.cur.name}.dynamodb"

  tags = { Name = "dynamodb-gateway-endpoint" }
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.terraform_private_rt.id
}

#IAM ROLE SETUP FOR EC2 TO ACCESS DDB
resource "aws_iam_role" "ec2_ddb_role" {
  name = "ec2-dynamodb-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ddb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "ec2-dynamodb-policy"
  role = aws_iam_role.ec2_ddb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DescribeTable" //in case my ec2's sdk needs it to connect to ddb
          //"dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.tf_ddb.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-dynamodb-instance-profile"
  role = aws_iam_role.ec2_ddb_role.name
}