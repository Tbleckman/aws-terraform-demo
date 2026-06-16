#MAKE THE ECS CLUSTER

resource "aws_ecs_cluster" "main" {
  name = "portfolio-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/portfolio/app"
  retention_in_days = 14
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionPolicy"
}

#MAKE NEW DYNAMODB ACCESS ROLE SINCE TRUST POLICY IS FOR EC2

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-dynamodb-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_dynamodb_access_policy" {
  name = "ecs-dynamodb-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Effect  = "Allow"
    Action = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:DescribeTable"
    ]
    Resource = aws_dynamodb_table.tf_ddb.arn
  })
}

#ECS TASK DEFINITION

resource "aws_ecs_task_definition" "portfolio_app" {
  family                   = "portfolio-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "portfolio-app"
      image     = "${aws_ecr_repository.portfolio_app.repository_url}:latest"
      essential = true

      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options   = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_app.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

#FARGATE SECURITY GROUP SETUP

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-fargate-sg"
  vpc_id = aws_vpc.terraform_testing.id
}

resource "aws_security_group_rule" "ecs_allow_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = aws_security_group.tf_sg.id
  protocol                 = "tcp"
  from_port                = 5000
  to_port                  = 5000
}

resource "aws_security_group_rule" "ecs_allow_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

#ECS SERVICE

resource "aws_ecs_service" "portfolio-app" {
  name            = "portfolio-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.portfolio_app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.terraform_testing_private_subnet1.id,
      aws_subnet.terraform_testing_private_subnet2.id
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.tf_alb_target_group.arn
    container_name   = "portfolio-app"
    container_port   = 5000
  }
  depends_on = [aws_alb_listener.https]
}