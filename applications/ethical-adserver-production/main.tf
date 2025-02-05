locals {
  location = "southeastasia"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "${local.name_prefix}-${local.env}"
}

resource "azurerm_storage_blob" "var_file_backup" {
  name                   = "terraform.tfvars"
  storage_account_name   = "adsterraformstates"
  storage_container_name = local.env
  type                   = "Block"
  source_content         = sensitive(file("terraform.tfvars"))
  content_md5            = filemd5("terraform.tfvars")
}
