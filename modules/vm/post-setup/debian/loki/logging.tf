locals {
  logging_private_ip = cidrhost(local.subnets[0].prefix, 20)
}

data "template_file" "install" {
  template = <<-EOT
    curl -O -L "https://github.com/grafana/loki/releases/download/v2.4.2/loki-linux-amd64.zip"
    unzip "loki-linux-amd64.zip"
    chmod a+x "loki-linux-amd64"
    sudo mv loki-linux-amd64 /usr/local/bin/loki

    wget https://raw.githubusercontent.com/grafana/loki/master/cmd/loki/loki-local-config.yaml
    sudo mkdir /etc/loki
    sudo mv loki-local-config.yaml /etc/loki/
    sudo mkdir /var/lib/loki
    sudo chown swarm:swarm /var/lib/loki
  EOT
}

data "template_file" "service" {
  template = <<-EOT
  [Unit]
  Description=Loki
  After=network.target

  [Service]
  Type=simple
  User=swarm
  ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-local-config.yaml

  [Install]
  WantedBy=multi-user.target
  EOT
}

# module "loki" {
#   source         = "../../modules/vm/azure/v1"
#   admin_username = ""
#   allowed_ports  = [3100]
#   file_uploads = [
#     {
#
#     }
#   ]
#   name_prefix    = "loki"
#   network = {
#     prefix = module.core_network.vnet_address_space[0]
#   }
#   private_ip_address  = local.logging_private_ip
#   private_key_pem     = module.swarm_cluster.ssh.private_key_pem
#   public_key          = module.swarm_cluster.ssh.public_key
#   resource_group_name = azurerm_resource_group.this.name
#   subnet = {
#     id     = module.core_network.vnet_subnets[0]
#     prefix = local.subnets[0].prefix
#   }
#   custom_data = ""
# }