resource "docker_config" "loki" {
  provider = docker.swarm

  data = base64encode(file("${path.module}/stacks/configs/loki.yaml"))
  name = "loki"
}

resource "docker_config" "promtail" {
  provider = docker.swarm

  data = base64encode(file("${path.module}/stacks/configs/promtail.yaml"))
  name = "promtail"
}