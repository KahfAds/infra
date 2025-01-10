output "storage_class" {
  value = {
    disk = kubernetes_storage_class.disk.metadata[0].name
    file = kubernetes_storage_class.file.metadata[0].name
  }
}