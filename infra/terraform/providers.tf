# -----------------------------------------------------------------------------
# Name:       providers.tf
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

# Exactly like pointing at EKS/GKE — only the context name changes.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = var.kube_context
  }
}
