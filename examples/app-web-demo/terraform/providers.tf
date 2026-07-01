provider "azurerm" {
  features {}

  # GUID factice : satisfait l'exigence subscription_id d'azurerm v4 pour `terraform validate`.
  # Aucun appel Azure n'est fait. Le client renseignera sa vraie souscription au déploiement.
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

provider "azapi" {
  subscription_id = "00000000-0000-0000-0000-000000000000"
}
