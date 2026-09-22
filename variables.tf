##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the Valkey instance will be created."
}

variable "name" {
  type        = string
  description = "The name to give the Valkey instance."
}

variable "valkey_version" {
  type        = string
  description = "Version of the Valkey instance to provision. If no value is passed, the current preferred version of IBM Cloud Databases is used."
  default     = null
}

variable "region" {
  type        = string
  description = "The region where you want to deploy your instance. For more information on which regions Gen2 is available, see [Feature differentiators](https://cloud.ibm.com/docs/cloud-databases-gen2?topic=cloud-databases-gen2-overview-gen1-gen2#feature-differentiators)."
  default     = "eu-de"
}

##############################################################################
# ICD hosting model properties
##############################################################################

variable "disk_mb" {
  type        = number
  description = "Allocated disk per member."
  default     = 20480

  validation {
    condition     = var.disk_mb >= 10240 && var.disk_mb <= 4096000
    error_message = "The disk per member must be between 10240 MB (10 GB) and 4096000 MB (4000 GB)."
  }
}

variable "member_host_flavor" {
  type        = string
  description = "Allocated host flavor per member. Valkey requires a dedicated host flavor — multitenant is not supported. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."

  validation {
    condition     = length(var.member_host_flavor) > 0
    error_message = "Member host flavor must be specified."
  }

  validation {
    condition     = var.member_host_flavor != "multitenant"
    error_message = "Shared compute, `multitenant`, is not supported for Valkey. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  }
}

variable "service_credential_names" {
  type = list(object({
    name     = string
    role     = optional(string, "Writer")
    endpoint = optional(string, "private")
  }))
  description = "List of service credentials to create for the database, including name and optionally role. Endpoint is always private for Valkey."
  default     = []

  validation {
    condition     = alltrue([for credential in var.service_credential_names : contains(["Writer", "Manager"], credential.role)])
    error_message = "`service_credential_names` role must be one of the following: `Writer` or `Manager`."
  }

  validation {
    condition     = alltrue([for credential in var.service_credential_names : credential.endpoint == "private"])
    error_message = "`service_credential_names` endpoint must be `private`. Valkey does not support public service endpoints."
  }
}

variable "resource_tags" {
  type        = list(string)
  description = "The list of resource tags to be added to the Databases for Valkey instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "Add access management tags to the resources created to control access. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#create-access-console)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection within terraform. This is not a property of the resource and does not prevent deletion outside of terraform. The database can not be deleted by terraform when this value is set to 'true'. In order to delete with terraform the value must be set to 'false' and a terraform apply performed before the destroy is performed. The default is 'true'."
  default     = true
}

variable "update_timeout" {
  type        = string
  description = "A database update may require a longer timeout for the update to complete. The default is 120 minutes. Set this variable to change the `update` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts)."
  default     = "120m"
}

variable "create_timeout" {
  type        = string
  description = "A database creation may require a longer timeout for the creation to complete. The default is 120 minutes. Set this variable to change the `create` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts)."
  default     = "120m"
}

variable "delete_timeout" {
  type        = string
  description = "A database deletion may require a longer timeout for the deletion to complete. The default is 15 minutes. Set this variable to change the `delete` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts)."
  default     = "15m"
}

##############################################################
# Encryption
##############################################################

variable "use_ibm_owned_encryption_key" {
  type        = bool
  description = "IBM Cloud Databases will secure your deployment's data at rest automatically with an encryption key that IBM hold. Alternatively, you may select your own Key Management System instance and encryption key (Key Protect or Key Protect Dedicated service) by setting this to false. If setting to false, a value must be passed for the `kms_key_crn` input."
  default     = true

  validation {
    condition = !(
      var.use_ibm_owned_encryption_key == true &&
      var.kms_key_crn != null
    )
    error_message = "When 'use_ibm_owned_encryption_key' is true, 'kms_key_crn' must be null."
  }

  validation {
    condition     = var.use_ibm_owned_encryption_key || var.kms_key_crn != null
    error_message = "When setting 'use_ibm_owned_encryption_key' to false, a value must be passed for 'kms_key_crn'."
  }
}

variable "kms_key_crn" {
  type        = string
  description = "The CRN of a Key Protect or Key Protect Dedicated Services encryption key to encrypt your data. Applies only if `use_ibm_owned_encryption_key` is false."
  default     = null

  validation {
    condition = anytrue([
      var.kms_key_crn == null,
      can(regex(".*kms.*", var.kms_key_crn))
    ])
    error_message = "Value must be the KMS key CRN from a Key Protect or Key Protect Dedicated Services instance."
  }
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of IAM authorization policies. When set to false (default), the following policies are created: (1) a policy that permits all Databases for Valkey instances in the given resource group 'Reader' access to the Key Protect or Key Protect Dedicated Services key provided in the `kms_key_crn` input (required for KMS encryption — skip only if one already exists in your account; no policy is created if `use_ibm_owned_encryption_key` is true), (2) a policy that permits Databases for Valkey instances in the given resource group 'Editor' access to the independent backups service (`gen2_independent_backups_policy`), and (3) a policy that permits Databases for Valkey instances in the given resource group 'Viewer' access to the resource group (`gen2_resource_group_policy`)."
  default     = false
}
