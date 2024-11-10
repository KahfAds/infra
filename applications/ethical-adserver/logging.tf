locals {
  docker_configs = {
    loki = {
      name = "loki"
      version = "3"
      content = file("${path.module}/stacks/configs/loki.yaml")
    }
    promtail = {
      name = "promtail"
      version = "6"
      content = file("${path.module}/stacks/configs/promtail.yaml")
    }
  }
}

resource "docker_config" "this" {
  provider = docker.swarm
  for_each = local.docker_configs

  data = base64encode(each.value.content)
  name = "${each.key}_v${each.value.version}"

  lifecycle {
    create_before_destroy = true
  }
}
