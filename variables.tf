# BEGIN: The following variables must be set by the cloud admin within AWS
variable "aws_region" {
  type = string
  description = "AWS Region, e.g. eu-central-1"

}

variable "file_storage_endpoint" {
  description = "S3 Regional endpoint"
  type        = string
}

variable "database_type"{
  type = string
  description = "Database type"
}

variable "database_jdbc_url" {
  type        = string
  description = "Database JDBC url, appending ?sslmode=prefer"
}

variable "database_name" {
  type        = string
  description = "Database name"
}

variable "database_username" {
  type        = string
  description = "Database username"
}

variable "database_password" {
  type = string
  description = "Database password"
}

variable "database_host" {
  type = string
  description = "Database host, appending the port :5432"
  
}

variable "aws_account_id"{
  type = string
  description = "AWS Account ID"
}

variable "aws_oidc_provider" {
  type = string
  description = "OIDC Provider"
}

variable "eks_cluster_server_api" {
  type = string
  description = "API Endpoint of the EKS cluster"
}

variable "eks_cluster_ca" {
  type = string
  description = "CA certificate of the EKS cluster"
}

variable "eks_cluster_token" {
  type = string
  description = "Token to authenticate to the EKS cluster"
}
# END: The following variables must be set by the cloud admin within AWS

#BEGIN: Portal UI variables 
variable "cluster_name" {
  type = string
  description = "Cluster name"
}

variable "namespace" {
  type = string
  description = "Namespace where the Mendix app hosted in"
}

variable "environment_internal_name" {
  type = string
  description = "Internal name for the Mendix app environment"
}