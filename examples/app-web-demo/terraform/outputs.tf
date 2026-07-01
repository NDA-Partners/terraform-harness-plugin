output "resource_group_name" {
  description = "Nom du resource group de l'application."
  value       = azurerm_resource_group.this.name
}

output "web_app_resource_id" {
  description = "Resource ID de la Web App."
  value       = module.app.resource_id
}

output "web_app_uri" {
  description = "URI de la Web App."
  value       = module.app.resource_uri
}

output "key_vault_uri" {
  description = "URI du Key Vault."
  value       = module.kv.uri
}

output "storage_account_name" {
  description = "Nom du compte de stockage."
  value       = module.sa.name
}
