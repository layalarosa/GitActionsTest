variable "resource_group_name" {
  description = "Nombre del resource group de Azure"
  type        = string
  default     = "rg-gitactions-test"
}

variable "location" {
  description = "Region de Azure"
  type        = string
  default     = "eastus"
}

variable "container_name" {
  description = "Nombre del container group"
  type        = string
  default     = "gitactions-app"
}

variable "image_tag" {
  description = "Tag de la imagen a desplegar"
  type        = string
  default     = "latest"
}

variable "dns_label" {
  description = "DNS label para el FQDN publico"
  type        = string
  default     = "gitactions-test"
}
