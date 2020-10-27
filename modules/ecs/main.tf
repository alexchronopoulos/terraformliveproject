# ECR Repo to store Docker images used by ECS task definitions
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.namespace}-ecr_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM assume role policy for ECS
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Create IAM role and assign policy
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.task}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Standard AWS ECS task execution role policy
data "aws_iam_policy" "ecs_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "iam_role_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_role_policy.arn
}

# ECS task definition 
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                = var.task
  container_definitions = <<JSON
[
    {
        "name": "${var.task}",
        "image": "${aws_ecr_repository.ecr_repo.repository_url}",
        "cpu": 256,
        "memory": 512,
        "essential": true,
        "portMappings": [
            {
                "containerPort": 5000,
                "hostPort": 5000
            }
        ]
    }
]
JSON
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.task_execution_role.arn

}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.namespace}-cluster"
}

resource "aws_ecs_service" "ecs_service" {
  name            = "flask"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1
  launch_type = "FARGATE"
  network_configuration {
      assign_public_ip = false

      security_groups = [
          var.sg.app
      ]

      subnets = [
          var.vpc.private_subnets[0],
          var.vpc.private_subnets[1],
          var.vpc.private_subnets[2]
      ]
  }

  load_balancer {
    target_group_arn = var.alb.target_group_arns[0]
    container_name   = var.task
    container_port   = 5000
  }
}