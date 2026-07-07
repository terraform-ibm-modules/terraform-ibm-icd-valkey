##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Valkey instance id"
  value       = ibm_database.valkey.id
}

output "version" {
  description = "Valkey instance version"
  value       = ibm_database.valkey.version
}

output "guid" {
  description = "Valkey instance guid"
  value       = ibm_database.valkey.guid
}

output "crn" {
  description = "Valkey instance crn"
  value       = ibm_database.valkey.resource_crn
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = local.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = local.service_credentials_object
  sensitive   = true
}

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict Valkey"
  value       = module.cbr_rule[*].rule_id
}

output "adminuser" {
  description = "Database admin user name"
  value       = ibm_database.valkey.adminuser
}
