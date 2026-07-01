# Spécification d'architecture : application web de démonstration

Sortie de l'agent `architecte-azure` à partir de `demande-exemple/demande-archi-exemple.md`. Validée avant
schématisation et génération.

## Contexte

Application web .NET en PaaS pour le application web de démonstration, environnement de qualification (QUA), dans un
resource group dédié. Besoins : hébergement web managé, coffre de secrets, stockage de fichiers, suivi
technique centralisé.

## Décisions sur les points ouverts

- Nom d'application : `webapp`, suffixe d'environnement `qua`.
- Plan App Service **dédié** (isolation de la squad), SKU modeste `B1` adapté à la qualification.
- Suivi centralisé via un workspace Log Analytics dédié.

## Briques AVM

Toutes couvertes par un AVM (voir `couverture-avm.md`), donc validées par construction.

| Rôle | Module AVM | Version épinglée | Statut |
|---|---|---|---|
| Resource group (conteneur) | `azurerm_resource_group` (natif) | provider `~> 4.0` | plomberie, hors AVM |
| Suivi centralisé | `Azure/avm-res-operationalinsights-workspace/azurerm` | `0.5.1` | couvert |
| Plan d'hébergement | `Azure/avm-res-web-serverfarm/azurerm` | `2.0.7` | couvert |
| Application web | `Azure/avm-res-web-site/azurerm` | `0.22.0` | couvert |
| Coffre de secrets | `Azure/avm-res-keyvault-vault/azurerm` | `0.10.2` | couvert |
| Stockage de fichiers | `Azure/avm-res-storage-storageaccount/azurerm` | `0.7.3` | couvert |

## Relations (câblages)

- Plan → App : `service_plan_resource_id`.
- App → Key Vault : accès par identité managée (rôle « Key Vault Secrets User »).
- App → Storage : accès par identité managée (rôle « Storage Blob Data Contributor »).
- App → Log Analytics : `diagnostic_settings`.
- Key Vault → Log Analytics : `diagnostic_settings`.

## Contraintes appliquées (constitution.md)

- Région UE (`francecentral` par défaut, portée par variable).
- 1 seul Storage et 1 seul Key Vault dans le resource group (quota respecté).
- Aucun secret en clair : accès par Managed Identity, pas de clé ni de chaîne de connexion.
- Versions AVM épinglées à l'exact. Tags obligatoires sur toutes les ressources.

## Points de vigilance relevés à la génération

- Interfaces AVM **non uniformes** : `serverfarm`, `web-site` et `storage` attendent `parent_id` (ID de
  resource group, style AzAPI), tandis que `keyvault` et `log-analytics` attendent `resource_group_name`.
- Le module `storage` 0.7.3 n'expose pas d'input `diagnostic_settings` de premier niveau : diagnostics du
  compte de stockage à câbler autrement, laissé hors démo.

## Points à valider par l'architecte

- Le nommage `webapp`/`qua` doit être remplacé par la convention réelle du client.
- Le tenant Azure AD du Key Vault (placeholder pour la vérification statique).
