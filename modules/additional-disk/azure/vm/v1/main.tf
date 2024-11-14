terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
resource "random_pet" "this" {}

resource "azurerm_managed_disk" "this" {
  name                 = "${var.name_prefix}-disk-${random_pet.this.id}"
  location             = var.resource_group.location
  resource_group_name  = var.resource_group.name
  storage_account_type = var.storage_account_type
  disk_size_gb         = var.disk_size_gb
  create_option        = var.create_option
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  managed_disk_id    = azurerm_managed_disk.this.id
  virtual_machine_id = var.virtual_machine_id
  lun                = var.logical_unit_number
  caching            = var.caching
}

resource "null_resource" "format_and_mount_disk" {
  depends_on = [azurerm_virtual_machine_data_disk_attachment.this]

  connection {
    type        = "ssh"
    host        = var.ssh.host
    user        = var.ssh.username
    private_key = var.ssh.private_key
  }

  provisioner "remote-exec" {
    when = create
    inline = [
      # Check if disk is already formatted
      "if ! sudo blkid /dev/disk/azure/scsi1/lun${var.logical_unit_number}; then",
      "sudo mkfs.ext4 /dev/disk/azure/scsi1/lun${var.logical_unit_number}",
      "fi",
      # Create a mount point
      var.create_mount_dir ? "sudo mkdir -p ${var.mount_point}" : "",
      # Mount the disk
      var.mount_now ? "sudo mount /dev/disk/azure/scsi1/lun${var.logical_unit_number} ${var.mount_point}" : "",
      # Update fstab to mount on boot
      var.mount_at_startup ? "sudo echo '/dev/disk/azure/scsi1/lun${var.logical_unit_number} ${var.mount_point} ext4 defaults,nofail 0 0' | sudo tee -a /etc/fstab" : ""
    ]
  }
}

# resource "null_resource" "remove_mount" {
#   depends_on = [null_resource.format_and_mount_disk]
#
#   connection {
#     type        = "ssh"
#     host        = self.triggers.user_name
#     user        = self.triggers.host
#     private_key = self.triggers.private_key
#   }
#
#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       # Update /etc/fstab
#       "sudo sed -i '\\|${self.triggers.mount_point}|d' /etc/fstab",
#       # Unmount disk
#       "sudo umount ${self.triggers.mount_point}",
#       # Remove the directory
#       "sudo rm -rf ${self.triggers.mount_point}"
#     ]
#   }
#
#   triggers = {
#     user_name   = var.ssh.username
#     private_key = var.ssh.private_key
#     host        = var.ssh.host
#     mount_point = var.mount_point
#     disk = azurerm_managed_disk.this.id
#   }
# }