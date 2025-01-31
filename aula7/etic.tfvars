deploy = {
  name = "nginx"
  containerName = "nginx"
  replicas = 3
  image = "nginx:alpine"
  port = 80
}

cluster = {
  name = "etic-cluster"
  nodes = 2
}