terraform {
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "0.4.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}

provider "minikube" {}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Define variables for clients
variable "clients" {
  type    = list(string)
  default = ["netflix", "meta", "rockstar"]
}

# Create dynamic namespaces
resource "kubernetes_namespace" "client_namespace" {
  for_each = toset(var.clients)

  metadata {
    name = each.key
  }
}

# PostgreSQL Secret (for database credentials)
resource "kubernetes_secret" "postgres_secret" {
  for_each = toset(var.clients)

  metadata {
    name      = "postgres-credentials-${each.key}"
    namespace = kubernetes_namespace.client_namespace[each.key].metadata[0].name
  }

  data = {
    POSTGRES_DB       = "odoo"
    POSTGRES_USER     = "odoo"
    POSTGRES_PASSWORD = "odoo_password_${each.key}"  # Unique password per client
  }
}

# PostgreSQL Persistent Volume Claim
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  for_each = toset(var.clients)

  metadata {
    name      = "postgres-data-${each.key}"
    namespace = kubernetes_namespace.client_namespace[each.key].metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "postgres" {
  for_each = toset(var.clients)

  metadata {
    name      = "postgres-${each.key}"
    namespace = kubernetes_namespace.client_namespace[each.key].metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres-${each.key}"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-${each.key}"
        }
      }

      spec {
        # Define the volume
        volume {
          name = "postgres-data-${each.key}"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc[each.key].metadata[0].name
          }
        }

        container {
          name  = "postgres-${each.key}"
          image = "postgres:latest"

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_secret[each.key].metadata[0].name
            }
          }

          port {
            container_port = 5432
          }

          # Mount the volume to the container
          volume_mount {
            name       = "postgres-data-${each.key}"
            mount_path = "/var/lib/postgresql/data"
          }
        }
      }
    }
  }
}

# Odoo Deployment
resource "kubernetes_deployment" "odoo" {
  for_each = toset(var.clients)

  metadata {
    name      = "odoo-${each.key}"
    namespace = kubernetes_namespace.client_namespace[each.key].metadata[0].name
  }

  spec {
    replicas = 1

    selector { match_labels = { app = "odoo-${each.key}" } }

    template {
      metadata { labels = { app = "odoo-${each.key}" } }

      spec {
        container {
          name  = "odoo-${each.key}"
          image = "odoo:latest"

          env {
            name  = "DB_HOST"
            value = "postgres-${each.key}"
          }
          port {
            container_port = 8069
          }
        }
      }
    }
  }
}

# Service for Odoo
resource "kubernetes_service" "odoo_service" {
  for_each = toset(var.clients)

  metadata {
    name      = "odoo-service-${each.key}"
    namespace = kubernetes_namespace.client_namespace[each.key].metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.odoo[each.key].metadata[0].name
    }

    port {
      port        = 80
      target_port = 8069
    }

    type = "ClusterIP"
  }
}

# Ingress for Odoo
resource "kubernetes_ingress_v1" "odoo_ingress" {  # Change to kubernetes_ingress_v1
  for_each = toset(var.clients)

  metadata {
    name      = "odoo-ingress-${each.key}"
    namespace = kubernetes_namespace.client_namespace[each.key].metadata[0].name
  }

  spec {
    rule {
      host = "odoo.${each.key}.local"  # Unique hostname for each client
      http {
        path {
          path     = "/"
          path_type = "Prefix"  # Specify path type
          backend {
            service {
              name = kubernetes_service.odoo_service[each.key].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}