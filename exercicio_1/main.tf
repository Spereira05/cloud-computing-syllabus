terraform {
  required_providers {
    minikube = {
      source = "scott-the-programmer/minikube"
      version = "0.4.4"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}

provider "minikube" {
  # Configuration options
}

provider "kubernetes" {
  # Configuration options
}

resource "minikube_cluster" "cluster" {
    cluster_name = "ex_1"
    nodes = 1
}

resource "kubernetes_namespace" "environment" {
    for_each = toset(var.namespaces)
    metadata {
        
    }
}