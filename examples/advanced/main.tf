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
# VPC
##############################################################################

resource "ibm_is_vpc" "example_vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "example_subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

locals {
  data_key_name = "${var.prefix}-valkey"
}

module "key_protect_all_inclusive" {
  source            = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version           = "5.6.5"
  resource_group_id = module.resource_group.resource_group_id
  # Note: Database instance and Key Protect must be created in the same region when using BYOK
  # See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [
    {
      key_ring_name = "icd"
      keys = [
        {
          key_name     = local.data_key_name
          force_delete = true
        }
      ]
    }
  ]
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# Create CBR Zone
##############################################################################

module "cbr_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.36.4"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone containing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc", # to bind a specific vpc to the zone
    value = ibm_is_vpc.example_vpc.crn,
  }]
}

##############################################################################
# Valkey Instance
##############################################################################

module "icd_valkey" {
  source = "../../"
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source  = "terraform-ibm-modules/icd-valkey/ibm"
  # version = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id            = module.resource_group.resource_group_id
  valkey_version               = var.valkey_version
  name                         = "${var.prefix}-valkey"
  region                       = var.region
  use_ibm_owned_encryption_key = false
  kms_key_crn                  = module.key_protect_all_inclusive.keys["icd.${local.data_key_name}"].crn
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
  access_tags         = var.access_tags
  member_host_flavor  = var.member_host_flavor
  deletion_protection = false
  cbr_rules = [
    {
      description      = "sample rule"
      enforcement_mode = "enabled"
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      tags = [
        {
          name  = "environment"
          value = "${var.prefix}-test"
        },
        {
          name  = "terraform-rule"
          value = "allow-${var.prefix}-vpc-to-${var.prefix}-valkey"
        }
      ]
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone.zone_id
        }]
      }]
    }
  ]
}
