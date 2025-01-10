resource "kubernetes_persistent_volume_claim" "azure_file_pvc" {
  metadata {
    name      = "azure-file-pvc"
    namespace = "default"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }

    storage_class_name = module.azure_csi_driver.storage_class.file
  }
}

resource "kubernetes_pod" "test_pod" {
  metadata {
    name      = "azure-file-test-pod"
    namespace = "default"
  }

  spec {
    container {
      name  = "test-container"
      image = "busybox"
      command = [
        "sleep",
        "3600"
      ]

      volume_mount {
        mount_path = "/mnt/azure"
        name       = "azure-file"
      }
    }

    volume {
      name = "azure-file"

      persistent_volume_claim {
        claim_name = "azure-file-pvc"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations
    ]
  }
}