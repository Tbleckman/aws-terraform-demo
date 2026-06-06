#ALB
resource "aws_lb" "tf_load_balancer" {
    name = "tf-alb"
    load_balancer_type = "application"
    security_groups = [aws_security_group.tf_sg.id]
    subnets = [aws_subnet.terraform_testing_public_subnet.id, aws_subnet.terraform_testing_public_subnet2.id]
    
    internal = false
    enable_deletion_protection = true 
    //tags = {Name = ""}
}

#SECURITY GROUP FOR ALB AND ITS IN/OUT RULES
resource "aws_security_group" "tf_sg" {
    name = "alb_in_out"
    description = "Allow all HTTP(S) traffic and all outbound traffic for alb"
    vpc_id = aws_vpc.terraform_testing.id

    tags = {Name = "alb_in/out"}
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_inbound_https" {
    description = "secure HTTPS traffic"
    
    security_group_id = aws_security_group.tf_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "tcp"

    from_port = 443
    to_port = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_inbound_http" {
    description = "HTTP web traffic"
    
    security_group_id = aws_security_group.tf_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "tcp"

    from_port = 80
    to_port = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv4" {
    security_group_id = aws_security_group.tf_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}