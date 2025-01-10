resource "helm_release" "file" {
  name       = "azurefile-csi"
  chart      = "azurefile-csi-driver"
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/charts"
  namespace  = var.namespace
  version    = "v1.31.0"

  set {
    name  = "controller.runOnControlPlane"
    value = "true"
  }

  set {
    name  = "controller.replicas"
    value = 1
  }

  set {
    name  = "controller.cloudConfigSecretName"
    value = kubernetes_secret.azure_cloud_provider.metadata[0].name
  }

  set {
    name  = "controller.cloudConfigSecretNamesapce"
    value = kubernetes_secret.azure_cloud_provider.metadata[0].namespace
  }

  set {
    name  = "node.cloudConfigSecretName"
    value = kubernetes_secret.azure_cloud_provider.metadata[0].name
  }

  set {
    name  = "node.cloudConfigSecretNamesapce"
    value = kubernetes_secret.azure_cloud_provider.metadata[0].namespace
  }

  lifecycle {
    replace_triggered_by = [kubernetes_secret.azure_cloud_provider.data]
  }
}

resource "kubernetes_storage_class" "file" {
  depends_on = [helm_release.file]
  metadata {
    name = "azurefile"
  }
  storage_provisioner = "file.csi.azure.com"
  parameters = {
    skuname = "Standard_LRS"
  }
  reclaim_policy = "Delete"
  volume_binding_mode = "Immediate"
}
