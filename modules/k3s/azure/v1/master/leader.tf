locals {
  admin_username = "azure-user"
  program = [
    "bash",
    "${path.module}/scripts/query-swarm.sh",
    base64encode(module.ssh_key.private_key_pem),
    local.admin_username,
    azurerm_public_ip.primary.ip_address
  ]

  remote_exec = concat([
    # Step 1: Create the cert directory
    "sudo mkdir -p /etc/docker/certs",
    "echo '{ \"metrics-addr\" : \"0.0.0.0:9323\", \"experimental\" : true}' | sudo tee /etc/docker/daemon.json",
    # Step 1: Write CA certificate to the correct directory
    "echo '${tls_self_signed_cert.ca_cert.cert_pem}' | sudo tee /etc/docker/certs/ca.pem",
    # Step 2: Write server certificate
    "echo '${tls_locally_signed_cert.server_cert.cert_pem}' | sudo tee /etc/docker/certs/server-cert.pem",
    # Step 3: Write server private key
    "echo '${tls_private_key.server_key.private_key_pem}' | sudo tee /etc/docker/certs/server-key.pem",
    # Step 4: Install Docker and start swarm
    "sudo apt-get update",
    "sudo apt-get install -y docker.io uidmap jq nfs-common",
    "yes | sudo ufw enable",
    "sudo ufw allow 22/tcp",
    "sudo ufw allow 2376/tcp",
    "sudo ufw allow 2377/tcp",
    "sudo ufw allow 7946/tcp",
    "sudo ufw allow 7946/udp",
    "sudo ufw allow 4789/udp",
    "sudo ufw allow 8080/tcp",
    "sudo ufw reload",
    # Step 5: Configure Docker with TLS certs
    "sudo sed -i 's|ExecStart=/usr/bin/dockerd -H fd://|ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2376 --tlsverify --tlscacert=/etc/docker/certs/ca.pem --tlscert=/etc/docker/certs/server-cert.pem --tlskey=/etc/docker/certs/server-key.pem|' /lib/systemd/system/docker.service",
    # Step 6: Reload and restart Docker to apply changes
    "sudo systemctl daemon-reload",
    "sudo systemctl restart docker",
    # Start docker swarm
    "PRIVATE_IP=$(curl -s -H Metadata:true --noproxy \"*\" \"http://169.254.169.254/metadata/instance?api-version=2021-02-01\" | jq -r \".network.interface[0].ipv4.ipAddress[0].privateIpAddress\")",
    "sudo docker swarm init --default-addr-pool 10.0.0.0/8 --default-addr-pool-mask-length 24 --listen-addr \"$PRIVATE_IP\" --advertise-addr \"$PRIVATE_IP\""
  ], local.registry_login)
}

module "ssh_key" {
  source              = "../../../../ssh-keys/azure/v1"
  location            = var.location
  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
}

resource "azurerm_availability_set" "this" {
  location                    = var.location
  name                        = "${var.name_prefix}-AS"
  resource_group_name         = var.resource_group_name
  platform_fault_domain_count = 2
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name_prefix}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_linux_virtual_machine" "leader" {
  name                            = "${var.name_prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.size
  disable_password_authentication = true
  availability_set_id             = azurerm_availability_set.this.id

  network_interface_ids = [azurerm_network_interface.primary.id]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    diff_disk_settings {
      option = "Local"
    }
  }

  computer_name  = var.name_prefix
  admin_username = local.admin_username

  admin_ssh_key {
    username   = local.admin_username
    public_key = module.ssh_key.public_key
  }

  connection {
    user        = local.admin_username
    type        = "ssh"
    host        = azurerm_public_ip.primary.ip_address
    private_key = module.ssh_key.private_key_pem
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  custom_data = base64encode(file("${path.module}/scripts/cloud-init.yaml"))


  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.roles
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = each.key
  scope                = each.value
}

data "external" "worker_join_command" {
  depends_on = [azurerm_linux_virtual_machine.leader]
  program = local.program
  query = {
    args = "worker"
  }
}

data "external" "join_command" {
  depends_on = [azurerm_linux_virtual_machine.leader]
  program = local.program
  query = {
    args = "manager"
  }
}