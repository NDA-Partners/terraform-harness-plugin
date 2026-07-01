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
