locals {
  nodes = concat([var.initiator_node], var.additional_nodes)
}