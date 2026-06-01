# Restore from backup example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-valkey-backup-restore-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/backup-restore">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

This example provides an end-to-end executable flow of how a Valkey instance can be created from a backup of an existing instance. This example uses the IBM Cloud Terraform provider to:

- Create a new resource group if one is not passed in.
- Create a restored Databases for Valkey instance pointing to the latest backup of the existing Valkey database instance CRN passed.
