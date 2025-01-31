resource "minikube_cluster" "my-cluster" {
    cluster_name = var.cluster.name
    driver = "docker"
    nodes = var.cluster.nodes
    addons = [
        "ingress"
    ]
}
