#EC2 INSTANCE CONFIGURATION
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

resource "aws_instance" "ec2_instance1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.terraform_testing_private_subnet1.id
  tags          = { Name = "Instance1" }

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("${path.module}/userdata/nginx.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "ec2_instance2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.terraform_testing_private_subnet2.id
  tags          = { Name = "Instance2" }

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("${path.module}/userdata/nginx.sh")
  user_data_replace_on_change = true
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.terraform_testing.id
}

resource "aws_security_group_rule" "ec2_allow_inbound" {
  security_group_id        = aws_security_group.ec2_sg.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.tf_sg.id

  protocol  = "tcp"
  to_port   = 80
  from_port = 80
}

resource "aws_security_group_rule" "ec2_allow_outbound" {
  security_group_id = aws_security_group.ec2_sg.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]

  to_port   = 0
  from_port = 0
  protocol  = "-1"
}