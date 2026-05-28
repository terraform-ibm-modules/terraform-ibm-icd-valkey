##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Valkey instance id"
  value       = ibm_database.valkey_database.id
}

output "version" {
  description = "Valkey instance version"
  value       = ibm_database.valkey_database.version
}

output "guid" {
  description = "Valkey instance guid"
  value       = ibm_database.valkey_database.guid
}

output "crn" {
  description = "Valkey instance crn"
  value       = ibm_database.valkey_database.resource_crn
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
  value       = ibm_database.valkey_database.adminuser
}

output "hostname" {
  description = "Database connection hostname"
  value       = data.ibm_database_connection.database_connection.valkey[0].hosts[0].hostname
}

output "port" {
  description = "Database connection port"
  value       = data.ibm_database_connection.database_connection.valkey[0].hosts[0].port
}

output "certificate_base64" {
  description = "Database connection certificate"
  value       = data.ibm_database_connection.database_connection.valkey[0].certificate[0].certificate_base64
  sensitive   = true
}
