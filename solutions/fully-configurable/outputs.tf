##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Valkey instance id"
  value       = local.valkey_id
}

output "version" {
  description = "Valkey instance version"
  value       = local.valkey_version
}

output "guid" {
  description = "Valkey instance guid"
  value       = local.valkey_guid
}

output "crn" {
  description = "Valkey instance crn"
  value       = local.valkey_crn
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = var.existing_valkey_instance_crn != null ? null : module.valkey[0].service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = var.existing_valkey_instance_crn != null ? null : module.valkey[0].service_credentials_object
  sensitive   = true
}

output "secrets_manager_secrets" {
  description = "Service credential secrets"
  value       = length(local.service_credential_secrets) > 0 ? module.secrets_manager_service_credentials[0].secrets : null
}

output "next_steps_text" {
  value       = "Your Database for Valkey instance is ready. You can now take advantage of reduced application response time, achieve cost-optimized performance, low latency, high throughput, in a highly available and scalable solution."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Deployment Details"
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://cloud.ibm.com/services/databases-for-valkey/${local.valkey_crn}?paneId=manage"
  description = "Primary URL"
}
