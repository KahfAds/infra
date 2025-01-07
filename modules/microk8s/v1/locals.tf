locals {
  nodes = concat([var.initiator_node], var.master_nodes, var.worker_nodes)
}