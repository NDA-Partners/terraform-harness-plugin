# Index de l'ontologie

Table « situation → page(s) à charger ». Les agents ne lisent pas toute l'ontologie : ils consultent cet
index et ne chargent que les pages utiles à la tâche en cours (chargement à la volée, façon Karpathy).

## Pages disponibles

| Page | Contenu |
|---|---|
| `constitution.md` | Règles non négociables (localisation, quotas par RG, sécurité, versions, nommage, tags). |
| `terraform-fondations.md` | Découpage des fichiers, `required_providers`, providers, backend local. |
| `avm-usage.md` | Consommer un AVM : source, version, inputs communs, interfaces, câblage, piège AzAPI. |
| `archetypes/app-service-keyvault-storage.md` | Briques AVM et câblage de l'archétype App Service + Key Vault + Storage. |

## Quelle page charger quand

| Situation | Pages à charger |
|---|---|
| Toute tâche, quelle qu'elle soit | `constitution.md` (toujours) |
| Comprendre une demande et mapper sur des AVM | `avm-usage.md` + l'archétype concerné |
| Demande d'application web PaaS (secrets, stockage, télémétrie) | `archetypes/app-service-keyvault-storage.md` |
| Générer le code Terraform | `terraform-fondations.md` + `avm-usage.md` + l'archétype + `constitution.md` |
| Vérifier le code généré | `constitution.md` (contrôle de conformité) |

## Ajouter un archétype

Créer une page `archetypes/<nom>.md` sur le modèle de l'archétype existant (briques AVM + câblage +
contraintes + demande type), puis l'ajouter aux deux tables ci-dessus.
