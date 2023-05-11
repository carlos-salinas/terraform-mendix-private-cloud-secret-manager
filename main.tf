locals {
  aws_secret_manager_entry = "${var.cluster_name}-${var.environment_internal_name}"
}

# Create a new secret on AWS Secret Manager and set its value
resource "aws_secretsmanager_secret" "apps_secrets" {
    name                    = local.aws_secret_manager_entry
    recovery_window_in_days = 7
}

# Set Secret value
resource "aws_secretsmanager_secret_version" "apps_secrets_version" {
    secret_id = aws_secretsmanager_secret.apps_secrets.id
    secret_string = jsonencode({
    storage-service-name = "com.mendix.storage.s3",
    storage-endpoint     = var.file_storage_endpoint
    storage-bucket-name  = var.environment_internal_name,
    database-type        = var.database_type,
    database-jdbc-url    = var.database_jdbc_url,
    database-name        = var.database_name,
    database-username    = var.database_username,
    database-password    = var.database_password,
    database-host        = var.database_host
    })
}

# IAM role with trust relationship to an EKS OIDC
resource "aws_iam_role" "app_irsa_role" {
    name = "${var.cluster_name}-app-role-${var.environment_internal_name}"
    assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
        {
        "Effect" : "Allow",
        "Principal" : {
            "Federated" : "arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.aws_oidc_provider}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
            "StringEquals" : {

            "${var.aws_oidc_provider}:sub" : "system:serviceaccount:${var.namespace}:${var.environment_internal_name}",
            "${var.aws_oidc_provider}:aud" : "sts.amazonaws.com"
            }
        }
        }
    ]
    })
}

# the inline policy for the IAM role
resource "aws_iam_role_policy" "app_irsa_policy" {
    name = "${var.cluster_name}-app-policy"
    role = aws_iam_role.app_irsa_role.id

    policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
        {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
        ],

        "Resource" : aws_secretsmanager_secret.apps_secrets.arn
        }
    ]
    })
}

# Create thee K8s service account which will get the AIM Role and the SecretProviderClass object mappping the secret value on AWS Secret Manage
resource "helm_release" "mendix_secret_store" {
  name      = "mendixsecretstore"
  chart     = "${path.module}/charts/mendix-secret-store"
  namespace = var.namespace
  values = [
    templatefile("${path.module}/helm-values/mendix-secret-store-values.yaml.tpl",
      {
        account_id                   = var.aws_account_id,
        cluster_name                 = var.cluster_name,
        namespace                    = var.namespace
        environment_internal_name    = var.environment_internal_name
    })
  ]
}