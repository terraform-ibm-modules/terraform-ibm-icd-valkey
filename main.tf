########################################################################################################################
# Parse info from KMS key CRN
########################################################################################################################

locals {
  parse_kms_key = !var.use_ibm_owned_encryption_key
}

module "kms_key_crn_parser" {
  count   = local.parse_kms_key ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.6.0"
  crn     = var.kms_key_crn
}

locals {
  kms_service           = local.parse_kms_key ? module.kms_key_crn_parser[0].service_name : null
  kms_account_id        = local.parse_kms_key ? module.kms_key_crn_parser[0].account_id : null
  kms_key_id            = local.parse_kms_key ? module.kms_key_crn_parser[0].resource : null
  kms_key_instance_guid = local.parse_kms_key ? module.kms_key_crn_parser[0].service_instance : null
}

########################################################################################################################
# KMS IAM Authorization Policy
########################################################################################################################

locals {
  # only create auth policy if 'use_ibm_owned_encryption_key' is false, and 'skip_iam_authorization_policy' is false
  create_kms_auth_policy = !var.use_ibm_owned_encryption_key && !var.skip_iam_authorization_policy ? 1 : 0
}

# Create IAM Authorization Policy to allow Valkey to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                    = local.create_kms_auth_policy
  source_service_name      = "databases-for-valkey"
  source_resource_group_id = var.resource_group_id
  roles                    = ["Reader"]
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

# icd-versions is commented out because the /v5/ibm/deployables API does not list
# 'valkey' in classic ICD regions, and Gen2 region endpoints (ca-mon, in-che) are
# only reachable from within IBM Cloud's private network. Version validation is
# handled by the IBM provider at plan/apply time.
#
# module "available_versions" {
#   source   = "terraform-ibm-modules/common-utilities/ibm//modules/icd-versions"
#   version  = "1.6.0"
#   region   = var.region
#   icd_type = "valkey"
# }
#
# locals {
#   icd_supported_versions = module.available_versions.supported_versions
# }


########################################################################################################################
# Valkey instance
########################################################################################################################

resource "ibm_database" "valkey" {
  depends_on          = [time_sleep.wait_for_authorization_policy]
  name                = var.name
  plan                = "standard-gen2" # Only standard-gen2 plan is available for Valkey
  location            = var.region
  service             = "databases-for-valkey"
  version             = var.valkey_version
  resource_group_id   = var.resource_group_id
  service_endpoints   = "private" # Valkey only supports private service endpoints
  deletion_protection = var.deletion_protection
  tags                = var.tags
  key_protect_key     = var.kms_key_crn

  group {
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

  lifecycle {
    ignore_changes = [
      # Ignore changes to these because a change will destroy and recreate the instance
      key_protect_key,
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
  resource_id = ibm_database.valkey.resource_crn
  tags        = var.access_tags
  tag_type    = "access"
}

##############################################################################
# Service Credentials
##############################################################################

resource "ibm_resource_key" "service_credentials" {
  for_each             = { for key in var.service_credential_names : key.name => key }
  name                 = each.key
  role                 = null
  resource_instance_id = ibm_database.valkey.id
  parameters = {
    service-endpoints = each.value.endpoint
    role_crn          = "crn:v1:bluemix:public:iam::::role:${each.value.role}"
  }
}

locals {
  # used for output only
  service_credentials_json = length(var.service_credential_names) > 0 ? {
    for service_credential in ibm_resource_key.service_credentials :
    service_credential["name"] => service_credential["credentials_json"]
  } : null

  service_credentials_object = length(var.service_credential_names) > 0 ? {
    hostname = ibm_resource_key.service_credentials[var.service_credential_names[0].name].credentials["connection.valkey.hosts.0.hostname"]
    port     = ibm_resource_key.service_credentials[var.service_credential_names[0].name].credentials["connection.valkey.hosts.0.port"]
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => {
        username = service_credential.credentials["username"]
        password = service_credential.credentials["password"]
      }
    }
  } : null
}
