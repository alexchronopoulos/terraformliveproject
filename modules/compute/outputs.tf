output "ecr_repo" {
    value = {
        arn = aws_ecr_repository.ecr_repo.arn
        registry_url = aws_ecr_repository.ecr_repo.repository_url
    }
}

output "ecs_cluster" {
    value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service" {
    value = aws_ecs_service.ecs_service.name
}