terraform {
  backend "s3" {
    region         = "eu-central-1"
    bucket         = "mx4pc-secrets-tf-state"
    key            = "terraform.tfstate"
    dynamodb_table = "mx4pc-secrets-tf-locking-state"
    encrypt        = true
  }

  required_version = ">= 0.14"


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.35"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_server_api
    cluster_ca_certificate = base64decode(var.eks_cluster_ca)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}