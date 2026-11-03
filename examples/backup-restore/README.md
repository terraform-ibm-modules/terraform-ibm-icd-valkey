# Backup restore example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-valkey-backup-restore-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-valkey/tree/main/examples/backup-restore">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

This example provides an end-to-end executable flow of how a Valkey DB instance can be restored from a backup. This example uses the IBM Cloud Terraform provider to:

- Create a new resource group if one is not passed in.
- Look up the latest available backup of an existing Valkey instance using the `ibm_database_backups` data source.
- Create a restored ICD Valkey database instance from that backup.

Provide the CRN of an existing Valkey instance that already has a backup via `existing_database_crn`. Valkey is Gen2 only, so the backup CRN is in the `databases-independent-backups` format:

```
crn:v1:bluemix:public:databases-independent-backups:<region>:a/<account-id>:<backup-id>::
```

The first independent backup of a new instance is not available immediately after provisioning, so the existing instance must have been running long enough to have a backup.
