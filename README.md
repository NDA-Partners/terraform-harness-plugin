# terraform-harness

Harness multi-agents pour **concevoir puis générer du Terraform Azure conforme**, à base d'**Azure Verified
Modules (AVM)**, validé sur un schéma et vérifié statiquement. Publié comme plugin Claude Code, conçu pour
être portable vers d'autres outils.

## Ce que fait le harness

Il outille la **revue d'architecture** : un workflow qui sépare deux temps, d'abord **valider l'architecture**
(le « quoi », logique Azure), ensuite **générer le code** (le « comment », Terraform).

```
demande d'architecture
   → spec de briques AVM        (validation humaine)
   → schéma DrawIO              (validation humaine)
   → code Terraform (.tf)
   → vérification statique      (fmt / validate / tflint)
```

Quatre rôles d'agents (architecte, schématiseur, rédacteur, vérificateur) et une ontologie de bonnes
pratiques chargée à la demande. Deux points de validation humaine (la spec, puis le schéma).

**Périmètre** : génération de code **+ vérification statique**. **Pas de déploiement, pas d'accès à une
souscription Azure.** Hors périmètre : `plan`/`apply`, Sentinel, brownfield, MCP.

## Architecture (portable, multi-outils)

Le repo sépare la **substance** de l'**emballage par outil** :

- `core/` : source **unique et neutre** (rôles d'agents, ontologie, workflow), indépendante de tout outil.
- `adapters/` : cibles générées par outil. Aujourd'hui : `adapters/claude-code/` (plugin Claude Code).
- `build/` : les scripts de génération (`core/` → `adapters/<outil>/`).

Les standards pivots d'interopérabilité sont **`SKILL.md`** et **`AGENTS.md`**. La sortie générée est
commitée (une installation ne relance pas le build).

**Roadmap** : d'autres adaptateurs (Cursor, Codex via `AGENTS.md`, etc.) pourront être ajoutés sans réécrire
la substance, en ajoutant un `build/build-<outil>.mjs` et un `adapters/<outil>/`.

## Prérequis

- **Claude Code**.
- **terraform** : `brew install hashicorp/tap/terraform` (absent du core Homebrew depuis le changement de
  licence HashiCorp).
- **tflint** : via son tap ou son binaire (absent du core Homebrew) — voir la doc tflint.

`terraform` et `tflint` ne servent qu'à l'étape de **vérification statique** (réseau requis pour télécharger
providers et modules, mais **aucune authentification Azure**).

## Installation (Claude Code)

```
/plugin marketplace add NDA-Partners/terraform-harness-plugin
/plugin install terraform-harness@nda-terraform-harness
```

Recharger la session si les agents et skills n'apparaissent pas immédiatement.

## Utilisation

Lancer la skill **`/generer-terraform`** (ou décrire une demande d'architecture). Le harness :

1. demande **où écrire les outputs** (obligatoire, aucun défaut) ;
2. produit une **spec** de briques AVM → validation ;
3. produit un **schéma DrawIO** → validation ;
4. génère le **code Terraform** ;
5. lance la **vérification statique**.

Un exemple complet de sortie est fourni dans [`examples/app-web-demo/`](examples/app-web-demo/) (spec,
schéma, code Terraform vérifié).

## Périmètre et limites

- Cible **Azure + Terraform** via **AVM**.
- **Génération + vérification statique uniquement** : pas de `plan`/`apply`, pas de déploiement, pas de
  Sentinel, pas de reprise d'existant (brownfield).
- MVP : **un archétype** (App Service + Key Vault + Storage).
- **Un seul adaptateur** (Claude Code) pour l'instant.
- Les AVM sont en pré-1.0 : le harness **épingle les versions** et signale la convention **AzAPI**.

## Contribuer

Voir [`CONTRIBUTING.md`](CONTRIBUTING.md). En résumé : **on modifie `core/`, jamais `adapters/` à la main**,
puis on relance le build (`node build/build-claude-code.mjs`).

## Licence

[Apache-2.0](LICENSE). Voir aussi [`NOTICE`](NOTICE).
