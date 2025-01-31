resource "kubernetes_namespace" "my_ns" {
    metadata {
        name = "dev"
    }
}