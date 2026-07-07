# Advanced example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-valkey-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/advanced">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

This example creates an IBM Cloud Database for Valkey instance with KMS encryption enabled configured.

The following resources are provisioned by this example:

- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet.
- A Key Protect instance with two root keys (one for data, one for backups) in the given resource group and region.
- An instance of Databases for Valkey with KMS encryption enabled.
- Service credentials for the database instance.
