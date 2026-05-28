##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Valkey
##############################################################################

module "database" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source  = "terraform-ibm-modules/icd-valkey/ibm"
  # version = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-valkey"
  region              = var.region
  valkey_version      = var.valkey_version
  access_tags         = var.access_tags
  tags                = var.resource_tags
  member_host_flavor  = var.member_host_flavor
  deletion_protection = false
  service_credential_names = [
    {
      name     = "valkey_admin"
      role     = "Administrator"
      endpoint = "private"
    },
    {
      name     = "valkey_operator"
      role     = "Operator"
      endpoint = "private"
    },
    {
      name     = "valkey_viewer"
      role     = "Viewer"
      endpoint = "private"
    },
    {
      name     = "valkey_editor"
      role     = "Editor"
      endpoint = "private"
    }
  ]
}
