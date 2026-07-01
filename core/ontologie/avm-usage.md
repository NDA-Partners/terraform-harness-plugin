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
