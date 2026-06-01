##############################################################################
# Outputs
##############################################################################

output "restored_icd_valkey_id" {
  description = "Restored Valkey instance id"
  value       = module.restored_icd_valkey.id
}

output "restored_icd_valkey_version" {
  description = "Restored Valkey instance version"
  value       = module.restored_icd_valkey.version
}
