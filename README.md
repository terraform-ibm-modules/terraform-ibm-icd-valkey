# IBM Cloud Databases for Valkey module

[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-icd-valkey?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-623CE4?logo=terraform)](https://registry.terraform.io/modules/terraform-ibm-modules/icd-valkey/ibm/latest)

This module implements an instance of IBM Cloud Databases for Valkey.

:exclamation: The module does not support major version upgrades or updates to encryption and backup encryption keys. To upgrade the version, create another instance of Databases for Valkey with the updated version and follow the steps in [Upgrading to a new Major Version](https://cloud.ibm.com/docs/databases-for-valkey?topic=databases-for-valkey-upgrading&interface=ui) in the IBM Cloud Docs.

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
<ul>
  <li><a href="#terraform-ibm-icd-valkey">terraform-ibm-icd-valkey</a></li>
  <li><a href="https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples">Examples</a>
    <ul>
      <li>
        <a href="https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/advanced">Advanced example</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-valkey-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/advanced"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
      <li>
        <a href="https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/basic">Basic example</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-valkey-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/basic"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
    </ul>
    ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
  </li>
  <li><a href="#contributing">Contributing</a></li>
</ul>
<!-- END OVERVIEW HOOK -->

## terraform-ibm-icd-valkey
### Usage

```terraform
provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX"
  region           = "us-south"
}

module "valkey" {
  source             = "terraform-ibm-modules/icd-valkey/ibm"
  version            = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  resource_group_id  = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  region             = "us-south"
  name               = "my-valkey-instance"
  member_host_flavor = "bx3d.4x20"
}
```

### Required IAM access policies

You need the following permissions to run this module.

- Account Management
    - **Databases for Valkey** service
        - `Editor` role access

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 2.2.2, < 3.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_available_versions"></a> [available\_versions](#module\_available\_versions) | terraform-ibm-modules/common-utilities/ibm//modules/icd-versions | 1.9.0 |
| <a name="module_kms_key_crn_parser"></a> [kms\_key\_crn\_parser](#module\_kms\_key\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.9.0 |

### Resources

| Name | Type |
|------|------|
| [ibm_database.valkey](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database) | resource |
| [ibm_iam_authorization_policy.kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_resource_key.service_credentials](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key) | resource |
| [ibm_resource_tag.access_tag](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_tag) | resource |
| [time_sleep.wait_for_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | Add access management tags to the resources created to control access. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#create-access-console). | `list(string)` | `[]` | no |
| <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout) | A database creation may require a longer timeout for the creation to complete. The default is 120 minutes. Set this variable to change the `create` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts). | `string` | `"120m"` | no |
| <a name="input_delete_timeout"></a> [delete\_timeout](#input\_delete\_timeout) | A database deletion may require a longer timeout for the deletion to complete. The default is 15 minutes. Set this variable to change the `delete` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts). | `string` | `"15m"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Enable deletion protection within terraform. This is not a property of the resource and does not prevent deletion outside of terraform. The database can not be deleted by terraform when this value is set to 'true'. In order to delete with terraform the value must be set to 'false' and a terraform apply performed before the destroy is performed. The default is 'true'. | `bool` | `true` | no |
| <a name="input_disk_mb"></a> [disk\_mb](#input\_disk\_mb) | Allocated disk per member. [Learn more](https://cloud.ibm.com/docs/databases-for-valkey?topic=databases-for-valkey-resources-scaling) | `number` | `20480` | no |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | The CRN of a Key Protect or Key Protect Dedicated Services encryption key to encrypt your data. Applies only if `use_ibm_owned_encryption_key` is false. | `string` | `null` | no |
| <a name="input_member_host_flavor"></a> [member\_host\_flavor](#input\_member\_host\_flavor) | Allocated host flavor per member. Valkey requires a dedicated host flavor — multitenant is not supported. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor). | `string` | n/a | yes |
| <a name="input_members"></a> [members](#input\_members) | Allocated number of members. Members can be scaled up but not down. | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to give the Valkey instance. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where you want to deploy your instance. For more information on which regions Gen2 is available, see [Feature differentiators](https://cloud.ibm.com/docs/cloud-databases-gen2?topic=cloud-databases-gen2-overview-gen1-gen2#feature-differentiators). | `string` | `"eu-de"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the Valkey instance will be created. | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | The list of resource tags to be added to the Databases for Valkey instance. | `list(string)` | `[]` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | List of service credentials to create for the database, including name and optionally role. Endpoint is always private for Valkey. | <pre>list(object({<br/>    name     = string<br/>    role     = optional(string, "Writer")<br/>    endpoint = optional(string, "private")<br/>  }))</pre> | `[]` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all Databases for Valkey instances in the given resource group 'Reader' access to the Key Protect or Key Protect Dedicated Services key provided in the `kms_key_crn` input. This policy is required in order to enable KMS encryption, so only skip creation if there is one already present in your account. No policy is created if `use_ibm_owned_encryption_key` is true. | `bool` | `false` | no |
| <a name="input_update_timeout"></a> [update\_timeout](#input\_update\_timeout) | A database update may require a longer timeout for the update to complete. The default is 120 minutes. Set this variable to change the `update` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts). | `string` | `"120m"` | no |
| <a name="input_use_ibm_owned_encryption_key"></a> [use\_ibm\_owned\_encryption\_key](#input\_use\_ibm\_owned\_encryption\_key) | IBM Cloud Databases will secure your deployment's data at rest automatically with an encryption key that IBM hold. Alternatively, you may select your own Key Management System instance and encryption key (Key Protect or Key Protect Dedicated service) by setting this to false. If setting to false, a value must be passed for the `kms_key_crn` input. | `bool` | `true` | no |
| <a name="input_valkey_version"></a> [valkey\_version](#input\_valkey\_version) | Version of the Valkey instance to provision. If no value is passed, the current preferred version of IBM Cloud Databases is used. | `string` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_adminuser"></a> [adminuser](#output\_adminuser) | Database admin user name |
| <a name="output_crn"></a> [crn](#output\_crn) | Valkey instance crn |
| <a name="output_guid"></a> [guid](#output\_guid) | Valkey instance guid |
| <a name="output_id"></a> [id](#output\_id) | Valkey instance id |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials object |
| <a name="output_version"></a> [version](#output\_version) | Valkey instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
