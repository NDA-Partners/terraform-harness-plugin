# Fondations Terraform

Structure et conventions de base du code généré. Chargée par `redacteur-terraform`.

## Découpage des fichiers

Un dossier par archétype généré, avec :

- `terraform.tf` : `required_version` + `required_providers` (versions épinglées).
- `providers.tf` : configuration des providers (`azurerm` avec `features {}`, `azapi`).
- `variables.tf` : entrées (location, nom d'application, environnement, tags communs).
- `locals.tf` : valeurs dérivées (nommage, tags fusionnés).
- `main.tf` : les blocs `module` AVM et le resource group.
- `outputs.tf` : sorties utiles (ids, noms).

## terraform.tf

```hcl
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azapi   = { source = "Azure/azapi", version = "~> 2.0" }
    random  = { source = "hashicorp/random", version = "~> 3.5" }
  }
  # Démo : state local. Cible client : backend distant (azurerm ou TFE).
  backend "local" {}
}
```

## providers.tf

```hcl
provider "azurerm" {
  features {}
  # subscription_id non requis pour `validate` (aucun appel API).
  # Renseigné par le client le jour d'un vrai déploiement.
}

provider "azapi" {}
```

## Conventions

- **Backend local** pour la démo (`backend "local"`), pas de remote state Azure. La cible client utiliserait
  un backend distant, hors périmètre ici.
- Nommage et tags dérivés dans `locals.tf` à partir des variables, jamais codés en dur dans les modules.
- Versions de modules AVM épinglées à l'exact (voir `constitution.md`).
- Pas de ressource de données (`data`) nécessitant un appel Azure, pour garder `validate` hors ligne d'authentification.
