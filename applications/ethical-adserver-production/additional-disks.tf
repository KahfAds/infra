locals {
  loki_mount_point = "/mnt/logging/loki"
}

module "logging_disk" {
  count = length(module.swarm_cluster.ssh.virtual_machines)
  source = "../../modules/additional-disk/azure/vm/v1"
  logical_unit_number = 1
  mount_point = local.loki_mount_point
  name_prefix = "${azurerm_resource_group.this.name}-logging-loki"
  resource_group = {
    name = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
  ssh = {
    host        = module.swarm_cluster.ssh.virtual_machines[count.index].ip_address
    username    = module.swarm_cluster.ssh.username
    private_key = module.swarm_cluster.ssh.private_key_pem
  }
  virtual_machine_id = module.swarm_cluster.ssh.virtual_machines[count.index].id
  chown = "10001:10001"
}