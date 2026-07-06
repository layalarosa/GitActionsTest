terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = replace("${var.resource_group_name}acr", "/[^a-zA-Z0-9]/", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_group" "app" {
  name                = var.container_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  container {
    name   = "nginx"
    image  = "${azurerm_container_registry.acr.login_server}/gitactions-frontend:${var.image_tag}"
    cpu    = 0.5
    memory = 1.5
    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  container {
    name   = "api"
    image  = "${azurerm_container_registry.acr.login_server}/gitactions-api:${var.image_tag}"
    cpu    = 0.5
    memory = 1.0
    ports {
      port     = 3000
      protocol = "TCP"
    }
    environment_variables = {
      DB_HOST     = "localhost"
      DB_PORT     = "5432"
      DB_USER     = "app"
      DB_PASSWORD = "app_secret"
      DB_NAME     = "appdb"
    }
  }

  container {
    name   = "db"
    image  = "postgres:16-alpine"
    cpu    = 0.5
    memory = 1.5
    ports {
      port     = 5432
      protocol = "TCP"
    }
    environment_variables = {
      POSTGRES_USER     = "app"
      POSTGRES_PASSWORD = "app_secret"
      POSTGRES_DB       = "appdb"
    }
  }

  dns_config {
    dns_label = var.dns_label
  }
}
