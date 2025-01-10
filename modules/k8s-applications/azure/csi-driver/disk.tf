terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.108.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

variable "resource_group_name" {
  type = string
}

variable "subnet_name" {}

variable "vnet_name" {}

variable "namespace" {}

variable "client_id" {}

resource "kubernetes_secret" "azure_cloud_provider" {
  metadata {
    name      = "azure-cloud-provider"
    namespace = var.namespace
  }

  data = {
    cloud-config = jsonencode({
      cloud                          = "AzurePublicCloud"
      tenantId                       = data.azurerm_client_config.current.tenant_id
      subscriptionId                 = data.azurerm_client_config.current.subscription_id
      resourceGroup                  = var.resource_group_name
      location                       = data.azurerm_resource_group.this.location
      useManagedIdentityExtension    = true
      userAssignedIdentityID         = var.client_id
      useInstanceMetadata            =  true
      vmType                         = "standard"
      subnetName                     = var.subnet_name
      vnetName                       = var.vnet_name
      vnetResourceGroup              = var.resource_group_name
    })
  }
}

resource "helm_release" "disk" {
  name       = "azuredisk-csi"
  chart      = "azuredisk-csi-driver"
  repository = "https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/charts"
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

resource "kubernetes_storage_class" "disk" {
  depends_on = [helm_release.disk]
  metadata {
    name = "azuredisk"
  }
  storage_provisioner = "disk.csi.azure.com"
  parameters = {
    skuname = "Standard_LRS"
    kind = "Managed"
  }
  reclaim_policy = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}
