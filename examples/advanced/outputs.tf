##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Valkey instance id"
  value       = module.icd_valkey.id
}

output "version" {
  description = "Valkey instance version"
  value       = module.icd_valkey.version
}

output "guid" {
  description = "Valkey instance guid"
  value       = module.icd_valkey.guid
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.icd_valkey.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.icd_valkey.service_credentials_object
  sensitive   = true
}

output "hostname" {
  description = "Valkey instance hostname"
  value       = module.icd_valkey.hostname
}

output "port" {
  description = "Valkey instance port"
  value       = module.icd_valkey.port
}
