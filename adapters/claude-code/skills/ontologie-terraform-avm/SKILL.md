---
name: ontologie-terraform-avm
description: Règles non négociables (constitution), fondations Terraform et usage des Azure Verified Modules. Connaissance transversale du harness Terraform.
---

# Constitution du harness

Règles non négociables que tous les agents respectent. Inspiration spec-kit (`constitution.md`). Tout code
généré qui enfreint une règle est rejeté par `verificateur-terraform`.

## Localisation

- Toute ressource est localisée dans une région **UE** (par défaut `francecentral`, alternative `westeurope`).
- La région est portée par une variable `location`, jamais codée en dur dans un module.

## Quotas par resource group

Contraintes du client (voir `reference-projet.md` §3), à graver dans le harness :

- **Max 1 Storage Account par resource group.**
- **Max 1 Key Vault par resource group.**
- **Max 1 Cosmos DB par resource group.**

Conséquence : une application qui a besoin de plusieurs comptes de stockage répartit ses ressources sur
plusieurs resource groups.

## Sécurité

- Chiffrement au repos activé partout (comportement par défaut des AVM, ne pas le désactiver).
- HTTPS seul, TLS 1.2 minimum sur les services exposés.
- **Aucun secret en clair** dans le code Terraform. Les secrets vivent dans Key Vault.
- Identité par **Managed Identity** plutôt que par clés ou chaînes de connexion quand le service le permet.

## Versions

- **Épingler la version exacte** de chaque module AVM (`version = "x.y.z"`, pas de `~>`). Les AVM sont en
  pré-1.0, des *breaking changes* surviennent entre versions mineures (voir `couverture-avm.md`).
- Providers épinglés en `~>` sur la version majeure.

## Provider

- Les AVM Terraform s'appuient sur le provider **AzAPI** en plus d'AzureRM. Déclarer les deux dans
  `required_providers`. Convention propre aux AVM, à signaler car elle diffère des habitudes AzureRM pur.

## Nommage et tags

- Convention de nommage : **placeholder à remplacer par les normes réelles du client**. Pattern de travail
  par défaut : `<type>-<app>-<env>-<instance>` (ex. `kv-monapp-qua-01`).
- Tags obligatoires sur toute ressource : `environment`, `owner`, `cost-center`, `project`.

## Périmètre

- La génération s'arrête au code. Aucun `plan`/`apply`, aucune action sur une souscription Azure.
- La vérification est **statique** : `fmt`, `validate`, `tflint`. Pas de credentials Azure.

---

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

---

# Consommer un Azure Verified Module

Comment câbler un AVM Terraform. Chargée par `architecte-azure` (mapping) et `redacteur-terraform` (génération).

## Source et version

```hcl
module "exemple" {
  source  = "Azure/avm-res-<rp>-<resource>/azurerm"
  version = "0.x.y"   # version exacte épinglée (constitution.md)
  # ...
}
```

La source est de la forme `Azure/avm-res-<resource-provider>-<type>/azurerm`. Exemples vérifiés (voir
`couverture-avm.md`) : `Azure/avm-res-web-site/azurerm`, `Azure/avm-res-keyvault-vault/azurerm`,
`Azure/avm-res-storage-storageaccount/azurerm`.

## Inputs communs à tous les AVM

- `name` : nom de la ressource.
- `location` : région (depuis la variable, jamais en dur).
- `resource_group_name` : RG de destination.
- `enable_telemetry` : télémétrie AVM. Mettre `false` en démo pour éviter une dépendance superflue.
- `tags` : tags communs (voir `constitution.md`).

## Interfaces AVM standardisées

Les AVM exposent des interfaces uniformes, à privilégier sur des modules dédiés :

- **`diagnostic_settings`** (map) : envoie les logs/métriques vers un `workspace_resource_id` (Log Analytics).
- **`private_endpoints`** (map) : private endpoints gérés dans le module de la ressource, plutôt que via
  le module standalone `avm-res-network-privateendpoint` (voir `couverture-avm.md` §3).
- **`managed_identities`** : `system_assigned = true` et/ou `user_assigned_resource_ids`.
- **`role_assignments`** (map) : attributions RBAC sur la ressource.
- **`lock`**, **`tags`** : verrou et tags.

## Câbler deux briques

Une relation entre deux briques se traduit par le passage d'un attribut de sortie de l'une en input de
l'autre. Exemples :

- App Service plan → Web App : `service_plan_resource_id = module.plan.resource_id`.
- Diagnostics → Log Analytics : `workspace_resource_id = module.law.resource_id` dans `diagnostic_settings`.
- App → Key Vault : identité managée de l'app + `role_assignments` côté Key Vault (rôle « Key Vault Secrets User »).

## Piège AzAPI

Les AVM utilisent le provider **AzAPI** en interne (en plus d'AzureRM). Toujours déclarer `azapi` dans
`required_providers` et `providers.tf`. Cette convention diffère d'un code AzureRM pur et doit être
expliquée au client habitué à AzureRM ou Bicep.
