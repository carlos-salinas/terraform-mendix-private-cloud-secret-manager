# AWS Secret Manager configuration for an app environment in Mendix for Private Cloud

## Introduction

This is a Terraform module which provisions and configures the required AWS resources and [K8S Secret Store CSI objects](https://secrets-store-csi-driver.sigs.k8s.io/) to allow a Mendix app to retrieve its environment settings from AWS Secret Manager, thus the app can store sensitive data externally, such as passwords,for easier gobernance and increased security.

## Steps to setup a new app enviroment

1. Create a new secret on AWS Secret Manager and set its value

    ```
    resource "aws_secretsmanager_secret" "apps_secrets" {
      name                    = var.secrets_manager_name
      recovery_window_in_days = 7
    }

    resource "aws_secretsmanager_secret_version" "apps_secrets_version" {
      secret_id = aws_secretsmanager_secret.apps_secrets.id
      secret_string = jsonencode({
        storage-service-name = "com.mendix.storage.s3",
        storage-endpoint     = var.file_storage_endpoint
        storage-bucket-name  = var.environment_internal_name,
        database-type        = var.database_type,
        database-jdbc-url    = var.database_jdb_url,
        database-name        = var.database_name,
        database-username    = var.database_username,
        database-password    = var.database_password,
        database-host        = var.database_host
      })
    }

    ```

2. IRSA Configuration to grant access to the secret. Mendix app will use a *K8s service account* to access its secret with read-only access. Therefore, a new IAM role with permissions to access the secret will created and propagated into the service account.

    ```
    # IAM role with trust relationship to an EKS OCDI
    resource "aws_iam_role" "app_irsa_role" {
      name = "${var.cluster_name}-app-role-${var.environment_internal_name}"
      assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Principal" : {
              "Federated" : "arn:aws:iam::${var.aws_caller_identity_account_id}:oidc-provider/${var.oidc_provider}"
            },
            "Action" : "sts:AssumeRoleWithWebIdentity",
            "Condition" : {
              "StringEquals" : {
                "${var.oidc_provider}:aud" : "sts.amazonaws.com",
                "${var.oidc_provider}:sub" : "${var.namespace}:${var.environment_internal_name}"
              }
            }
          }
        ]
      })
    }
    ```

3. Inline permission policy

    ```
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
    ```

4. Create the *K8s service account* which will get the AIM Role. This service account will grant the Mendix apps read-only access to AWS Secret Manager to retrieve its secret

    ```
        ## Create sa for the app to acccess the secret store
        apiVersion: v1
        automountServiceAccountToken: true
        kind: ServiceAccount
        metadata:
          annotations:
            eks.amazonaws.com/role-arn: arn:aws:iam::{{ $.Values.accountID }}:role/{{ $.Values.clusterName }}-app-role-{{ $.Values.environmentInternalName }}
            privatecloud.mendix.com/environment-account: "true"
          name: {{ $.Values.environmentInternalName }}
          namespace: mendix
    ```

5. Create the `SecretProviderClass` object which maps the secret value on AWS Secret Manager with the corresponding app environment settings in the K8s namespace

    ```
        apiVersion: secrets-store.csi.x-k8s.io/v1
        kind: SecretProviderClass
        metadata:
          name: {{ . }}
          namespace: mendix
          annotations:
            privatecloud.mendix.com/environment-class: "true"
        spec:
          provider: aws
          parameters:
            objects: |
              - objectName: "{{ $.Values.clusterName }}-{{ $.Values.environmentInternalName }}-secrets"
                objectType: secretsmanager
                jmesPath:
                - path: '"database-type"'
                  objectAlias: "database-type"
                - path: '"database-jdbc-url"'
                  objectAlias: "database-jdbc-url"
                - path: '"database-username"'
                  objectAlias: "database-username"
                - path: '"database-password"'
                  objectAlias: "database-password"
                - path: '"database-host"'
                  objectAlias: "database-host"
                - path: '"database-name"'
                  objectAlias: "database-name"
                - path: '"storage-service-name"'
                  objectAlias: "storage-service-name"
                - path: '"storage-endpoint"'
                  objectAlias: "storage-endpoint"
                - path: '"storage-bucket-name"'
                  objectAlias: "storage-bucket-name"
    ```