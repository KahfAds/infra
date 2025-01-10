# resource "kubernetes_persistent_volume_claim" "azure_disk_pvc" {
#   metadata {
#     name      = "azure-disk-pvc"
#     namespace = "default"
#   }
#
#   spec {
#     access_modes = ["ReadWriteOnce"]
#
#     resources {
#       requests = {
#         storage = "10Gi"
#       }
#     }
#
#     storage_class_name = module.azure_csi_driver.storage_class.disk
#   }
# }
#
# resource "kubernetes_pod" "test_pod" {
#   metadata {
#     name      = "azure-disk-test-pod"
#     namespace = "default"
#   }
#
#   spec {
#     container {
#       name  = "test-container"
#       image = "busybox"
#       command = [
#         "sleep",
#         "3600"
#       ]
#
#       volume_mount {
#         mount_path = "/mnt/azure"
#         name       = "azure-disk"
#       }
#     }
#
#     volume {
#       name = "azure-disk"
#
#       persistent_volume_claim {
#         claim_name = "azure-disk-pvc"
#       }
#     }
#   }
#
#   lifecycle {
#     ignore_changes = [
#       metadata[0].annotations
#     ]
#   }
# }