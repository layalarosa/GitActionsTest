output "acr_login_server" {
  description = "URL del Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "app_fqdn" {
  description = "FQDN de la aplicacion desplegada"
  value       = azurerm_container_group.app.fqdn
}

output "resource_group" {
  description = "Nombre del resource group"
  value       = azurerm_resource_group.main.name
}
