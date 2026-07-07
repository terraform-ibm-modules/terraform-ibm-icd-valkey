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
  default     = "9.0"

  # Version validation against the live ICD deployables API is not possible for
  # Valkey Gen2 — see the comment in main.tf. The IBM provider validates the version
  # at plan/apply time and surfaces a clear error if the version is unsupported.
}

variable "region" {
  type        = string
  description = "The region where you want to deploy your instance."
  default     = "eu-de"
}

##############################################################################
# ICD hosting model properties
##############################################################################

variable "members" {
  type        = number
  description = "Allocated number of members. Members can be scaled up but not down."
  default     = 3
  # Validation is done in terraform plan phase by IBM provider, so no need to add any extra validation here
}

variable "disk_mb" {
  type        = number
  description = "Allocated disk per member. [Learn more](https://cloud.ibm.com/docs/databases-for-valkey?topic=databases-for-valkey-resources-scaling)"
  default     = 20480
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "member_host_flavor" {
  type        = string
  description = "Allocated host flavor per member. Valkey requires a dedicated host flavor — multitenant is not supported. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "service_credential_names" {
  type = list(object({
    name     = string
    role     = optional(string, "Viewer")
    endpoint = optional(string, "private")
  }))
  description = "List of service credentials to create for the database, including name and optionally role. Endpoint is always private for Valkey."
  default     = []

  validation {
    condition     = alltrue([for credential in var.service_credential_names : contains(["Administrator", "Operator", "Viewer", "Editor"], credential.role)])
    error_message = "`service_credential_names` role must be one of the following: `Administrator`, `Operator`, `Viewer` or `Editor`."
  }

  validation {
    condition     = alltrue([for credential in var.service_credential_names : credential.endpoint == "private"])
    error_message = "`service_credential_names` endpoint must be `private`. Valkey does not support public service endpoints."
  }
}

variable "tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the Valkey instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Valkey instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
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
  description = "IBM Cloud Databases will secure your deployment's data at rest automatically with an encryption key that IBM hold. Alternatively, you may select your own Key Management System instance and encryption key (Key Protect or Hyper Protect Crypto Services) by setting this to false. If setting to false, a value must be passed for the `kms_key_crn` input."
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
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services encryption key to encrypt your data. Applies only if `use_ibm_owned_encryption_key` is false."
  default     = null

  validation {
    condition = anytrue([
      var.kms_key_crn == null,
      can(regex(".*kms.*", var.kms_key_crn)),
      can(regex(".*hs-crypto.*", var.kms_key_crn)),
    ])
    error_message = "Value must be the KMS key CRN from a Key Protect or Hyper Protect Crypto Services instance."
  }
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Databases for Valkey instances in the given resource group 'Reader' access to the Key Protect or Hyper Protect Crypto Services key provided in the `kms_key_crn` input. This policy is required in order to enable KMS encryption, so only skip creation if there is one already present in your account. No policy is created if `use_ibm_owned_encryption_key` is true."
  default     = false
}

##############################################################
# Context-based restriction (CBR)
##############################################################

variable "cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    tags = optional(list(object({
      name  = string
      value = string
    })))
  }))
  description = "The context-based restrictions rule to create. Only one rule is allowed."
  default     = []
  # Validation happens in the rule module
  validation {
    condition     = length(var.cbr_rules) <= 1
    error_message = "Only one CBR rule is allowed."
  }
}
