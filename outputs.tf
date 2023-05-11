output "aws_secret" {
  description = "AWS secret used by the app environment"
  value = aws_secretsmanager_secret.apps_secrets.arn
}

output "aim_role" {
  description = "IAM Role used by the Mendix app to retrieve the secret"
  value = aws_iam_role.app_irsa_role.arn
}