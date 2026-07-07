variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example"
  default     = "eu-de"
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example"
  default     = "valkey"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Valkey instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []
}

variable "valkey_version" {
  description = "Version of the Valkey instance. If no value is passed, the current preferred version of IBM Cloud Databases is used."
  type        = string
  default     = null
}

variable "member_host_flavor" {
  type        = string
  description = "The host flavor per member. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  default     = "bx3d.4x20"
}
