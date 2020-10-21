output "iam_role_arns" {
    value = {
        flask = aws_iam_role.flask-task-execution-role.arn
    }
}