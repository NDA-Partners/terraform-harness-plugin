# Archétype : App Service + Key Vault + Storage

Application web PaaS avec son coffre de secrets, son compte de stockage et sa télémétrie centralisée, dans
un resource group dédié. Archétype pilote du MVP.

## Briques AVM

| Rôle | Module AVM | Version (juin 2026) |
|---|---|---|
| Log Analytics (diagnostics) | `Azure/avm-res-operationalinsights-workspace/azurerm` | épingler la dernière |
| App Service Plan | `Azure/avm-res-web-serverfarm/azurerm` | épingler la dernière |
| Web App (App Service) | `Azure/avm-res-web-site/azurerm` | `0.22.0` |
| Key Vault | `Azure/avm-res-keyvault-vault/azurerm` | `0.10.2` |
| Storage Account | `Azure/avm-res-storage-storageaccount/azurerm` | `0.7.3` |

Le resource group est créé via une ressource `azurerm_resource_group` (conteneur de plomberie, pas une
brique applicative). Toutes les briques applicatives sont des AVM.

## Câblage

```
azurerm_resource_group (rg)
   ├── avm-res-operationalinsights-workspace (law)
   ├── avm-res-web-serverfarm (plan)
   ├── avm-res-web-site (app)
   │      service_plan_resource_id = plan.resource_id
   │      managed_identities { system_assigned = true }
   │      diagnostic_settings → law.resource_id
   ├── avm-res-keyvault-vault (kv)
   │      diagnostic_settings → law.resource_id
   │      role_assignments : app (Key Vault Secrets User) sur kv
   └── avm-res-storage-storageaccount (sa)
          diagnostic_settings → law.resource_id
          role_assignments : app (Storage Blob Data Contributor) sur sa
```

## Contraintes à respecter

- **1 seul Storage et 1 seul Key Vault dans ce resource group** (constitution.md). L'archétype les place
  tous deux dans le RG de l'application, ce qui sature le quota : pas de second compte de stockage ici.
- Région UE, tags obligatoires, versions épinglées (constitution.md).
- L'App accède au Key Vault et au Storage par **identité managée** (pas de clé ni de chaîne de connexion
  en clair).

## Demande type qui déclenche cet archétype

Toute demande d'une application web hébergée en PaaS qui a besoin de stocker des secrets et des fichiers,
avec un suivi technique centralisé. Mots-clés : App Service, web app, coffre, secrets, stockage, blob,
télémétrie, Log Analytics.
