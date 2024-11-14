module "monitoring" {
  source = "./stacks/monitoring"
  storage_account_name = module.nfs.account
  nfs_endpoint = module.nfs.endpoint
}