output "this" {
  value = {
    swarm = {
      ip_addresses = module.swarm_cluster.ssh.virtual_machines
      db_password = nonsensitive(azurerm_postgresql_flexible_server.this.administrator_password)
    }
  }
}

# output "sas" {
#   value = {
#     endpoint = module.blob.primary_blob_host
#     token = module.blob.sas_token
#   }
#   sensitive = true
# }