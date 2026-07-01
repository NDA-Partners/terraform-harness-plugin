variable "location" {
  type        = string
  description = "Région Azure (UE)."
  default     = "francecentral"
}

variable "tenant_id" {
  type        = string
  description = "Tenant Azure AD pour le Key Vault. Renseigné par le client au déploiement."
  # GUID factice : suffisant pour `terraform validate`, à remplacer par le vrai tenant.
  default = "00000000-0000-0000-0000-000000000000"
}
