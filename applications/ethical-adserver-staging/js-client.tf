module "js_client" {
  source = "./stacks/js-client"
  AZURE_CLIENT_ID = module.blob.credentials.username
  AZURE_CLIENT_SECRET = module.blob.credentials.password
  AZURE_TENANT_ID = module.blob.credentials.tenant_id
  AZURE_STORAGE_ACCOUNT = module.blob.account
  AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
  env = local.env
}