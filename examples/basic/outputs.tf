##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Valkey instance id"
  value       = module.database.id
}

output "valkey_crn" {
  description = "Valkey CRN"
  value       = module.database.crn
}

output "version" {
  description = "Valkey instance version"
  value       = module.database.version
}

output "adminuser" {
  description = "Database admin user name"
  value       = module.database.adminuser
}
