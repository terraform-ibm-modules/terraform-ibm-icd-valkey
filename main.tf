########################################################################################################################
# Locals
########################################################################################################################

locals {
  # If no value passed for 'backup_encryption_key_crn' use the value of 'kms_key_crn' and perform validation of 'kms_key_crn' to check if region is supported by backup encryption key.

  # If 'use_ibm_owned_encryption_key' is true or 'use_default_backup_encryption_key' is true, default to null.
  # If no value is passed for 'backup_encryption_key_crn', then default to use 'kms_key_crn'.
  backup_encryption_key_crn = var.use_ibm_owned_encryption_key || var.use_default_backup_encryption_key ? null : (var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : var.kms_key_crn)
}

########################################################################################################################
# Parse info from KMS key CRNs
########################################################################################################################

locals {
  parse_kms_key        = !var.use_ibm_owned_encryption_key
  parse_backup_kms_key = !var.use_ibm_owned_encryption_key && !var.use_default_backup_encryption_key
}

module "kms_key_crn_parser" {
  count   = local.parse_kms_key ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.6.0"
  crn     = var.kms_key_crn
}

module "backup_key_crn_parser" {
  count   = local.parse_backup_kms_key ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.6.0"
  crn     = local.backup_encryption_key_crn
}

# Put parsed values into locals
locals {
  kms_service                  = local.parse_kms_key ? module.kms_key_crn_parser[0].service_name : null
  kms_account_id               = local.parse_kms_key ? module.kms_key_crn_parser[0].account_id : null
  kms_key_id                   = local.parse_kms_key ? module.kms_key_crn_parser[0].resource : null
  kms_key_instance_guid        = local.parse_kms_key ? module.kms_key_crn_parser[0].service_instance : null
  backup_kms_service           = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].service_name : null
  backup_kms_account_id        = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].account_id : null
  backup_kms_key_id            = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].resource : null
  backup_kms_key_instance_guid = local.parse_backup_kms_key ? module.backup_key_crn_parser[0].service_instance : null
}

########################################################################################################################
# KMS IAM Authorization Policies
########################################################################################################################

locals {
  # only create auth policy if 'use_ibm_owned_encryption_key' is false, and 'skip_iam_authorization_policy' is false
  create_kms_auth_policy = !var.use_ibm_owned_encryption_key && !var.skip_iam_authorization_policy ? 1 : 0
  # only create backup auth policy if 'use_ibm_owned_encryption_key' is false, 'skip_iam_authorization_policy' is false and 'use_same_kms_key_for_backups' is false
  create_backup_kms_auth_policy = !var.use_ibm_owned_encryption_key && !var.skip_iam_authorization_policy && !var.use_same_kms_key_for_backups ? 1 : 0
}

# Create IAM Authorization Policies to allow Valkey to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                    = local.create_kms_auth_policy
  source_service_name      = "databases-for-valkey"
  source_resource_group_id = var.resource_group_id
  roles                    = ["Reader", "Authorization Delegator"] # Authorization Delegator role required for backup encryption key
  description              = "Allow all Valkey instances in the resource group ${var.resource_group_id} to read the ${local.kms_service} key ${local.kms_key_id} from the instance GUID ${local.kms_key_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.kms_key_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  count      = local.create_kms_auth_policy
  depends_on = [ibm_iam_authorization_policy.kms_policy]

  create_duration = "30s"
}

resource "ibm_iam_authorization_policy" "backup_kms_policy" {
  count                    = local.create_backup_kms_auth_policy
  source_service_name      = "databases-for-valkey"
  source_resource_group_id = var.resource_group_id
  roles                    = ["Reader", "Authorization Delegator"] # Authorization Delegator role required for backup encryption key
  description              = "Allow all Valkey instances in the Resource Group ${var.resource_group_id} to read the ${local.backup_kms_service} key ${local.backup_kms_key_id} from the instance GUID ${local.backup_kms_key_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.backup_kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.backup_kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.backup_kms_key_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.backup_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_backup_kms_authorization_policy" {
  count           = local.create_backup_kms_auth_policy
  depends_on      = [ibm_iam_authorization_policy.backup_kms_policy]
  create_duration = "30s"
}


module "available_versions" {
  source   = "terraform-ibm-modules/common-utilities/ibm//modules/icd-versions"
  version  = "1.6.0"
  region   = var.region
  icd_type = "valkey"
}

locals {
  icd_supported_versions = module.available_versions.supported_versions
}


########################################################################################################################
# Valkey instance
########################################################################################################################

resource "ibm_database" "valkey_database" {
  depends_on                  = [time_sleep.wait_for_authorization_policy]
  name                        = var.name
  plan                        = "standard-gen2" # Only standard-gen2 plan is available for Valkey
  location                    = var.region
  service                     = "databases-for-valkey"
  version                     = var.valkey_version
  resource_group_id           = var.resource_group_id
  service_endpoints           = "private" # Valkey only supports private service endpoints
  deletion_protection         = var.deletion_protection
  version_upgrade_skip_backup = var.version_upgrade_skip_backup
  tags                        = var.tags
  key_protect_key             = var.kms_key_crn
  backup_encryption_key_crn   = local.backup_encryption_key_crn
  backup_id                   = var.backup_crn

  ## This block is only added when not restoring from a backup, as group configuration is inherited from the backup.
  dynamic "group" {
    for_each = var.backup_crn == null ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
      host_flavor {
        id = var.member_host_flavor
      }
      disk {
        allocation_mb = var.disk_mb
      }
      members {
        allocation_count = var.members
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to these because a change will destroy and recreate the instance
      key_protect_key,
      backup_encryption_key_crn,
    ]
  }

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }
}

resource "ibm_resource_tag" "access_tag" {
  count       = length(var.access_tags) == 0 ? 0 : 1
  resource_id = ibm_database.valkey_database.resource_crn
  tags        = var.access_tags
  tag_type    = "access"
}

##############################################################################
# Context Based Restrictions
##############################################################################

module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.36.4"
  rule_description = var.cbr_rules[count.index].description
  enforcement_mode = var.cbr_rules[count.index].enforcement_mode
  rule_contexts    = var.cbr_rules[count.index].rule_contexts
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = var.cbr_rules[count.index].account_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = ibm_database.valkey_database.id
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "databases-for-valkey"
        operator = "stringEquals"
      }
    ]
  }]
  operations = [{
    api_types = [
      {
        api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:data-plane"
      }
    ]
  }]
}

##############################################################################
# Service Credentials
##############################################################################

resource "ibm_resource_key" "service_credentials" {
  for_each             = { for key in var.service_credential_names : key.name => key }
  name                 = each.key
  role                 = each.value.role
  resource_instance_id = ibm_database.valkey_database.id
  parameters = {
    service-endpoints = each.value.endpoint
  }
}

locals {
  # used for output only
  service_credentials_json = length(var.service_credential_names) > 0 ? {
    for service_credential in ibm_resource_key.service_credentials :
    service_credential["name"] => service_credential["credentials_json"]
  } : null

  service_credentials_object = length(var.service_credential_names) > 0 ? {
    hostname    = ibm_resource_key.service_credentials[var.service_credential_names[0].name].credentials["connection.valkey.hosts.0.hostname"]
    certificate = ibm_resource_key.service_credentials[var.service_credential_names[0].name].credentials["connection.valkey.certificate.certificate_base64"]
    port        = ibm_resource_key.service_credentials[var.service_credential_names[0].name].credentials["connection.valkey.hosts.0.port"]
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => {
        username = service_credential.credentials["connection.valkey.authentication.username"]
        password = service_credential.credentials["connection.valkey.authentication.password"]
      }
    }
  } : null
}

data "ibm_database_connection" "database_connection" {
  endpoint_type = "private"
  deployment_id = ibm_database.valkey_database.id
  user_id       = ibm_database.valkey_database.adminuser
  user_type     = "database"
}
