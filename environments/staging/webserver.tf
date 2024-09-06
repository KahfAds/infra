module "vm_servers" {
  source = "../../src/vm/azure/v1"
  admin_username = ""
  availability_set_id = ""
  location = ""
  name_prefix = ""
  resource_group_name = ""
  rsa_key_name = ""
  size = ""
  subnet_id = ""
}