terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

locals {
  kube_host = "https://127.0.0.1:6443"
}

provider "kubernetes" {
  host        = local.kube_host
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    host        = local.kube_host
    config_path = var.kubeconfig_path
  }
}

