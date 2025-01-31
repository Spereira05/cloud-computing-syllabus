environment = [ "dev", "qa", "prod" ]

deploy = {
  name = "app"
  containerName = "nginx"
  replicas = 1
  image = "nginx:alpine"
  port = 80
}

cluster = {
  name = "dengun"
  nodes = 3
}