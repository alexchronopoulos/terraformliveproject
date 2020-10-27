output "ecr_repo" {
    value = {
        arn = aws_ecr_repository.ecr_repo.arn
        registry_url = aws_ecr_repository.ecr_repo.repository_url
    }
}