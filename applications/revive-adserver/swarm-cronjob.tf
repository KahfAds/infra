locals {
  stack_swarm_cronjob = base64encode(file("${path.module}/stacks/swarm-cronjob.yaml"))
}