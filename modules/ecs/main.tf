resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.namespace}-ecr_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_task_definition" "flask" {
  family                = "flask"
  container_definitions = <<JSON
[
    {
        "name": "flask",
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
  execution_role_arn = var.iam_role_arns.flask

}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.namespace}-cluster"
}

resource "aws_ecs_service" "flask" {
  name            = "flask"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.flask.arn
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
    container_name   = "flask"
    container_port   = 5000
  }
}
