<div align="center">

# 🏗️ terraform-harness

**Décris ton architecture Azure. Récupère du Terraform conforme, validé sur un schéma et vérifié.**

Un harness multi-agents pour Claude Code qui transforme une demande d'architecture en code Terraform
à base d'[Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/), avec l'humain aux commandes.

![Licence](https://img.shields.io/badge/licence-Apache--2.0-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2)
![Terraform](https://img.shields.io/badge/Terraform-Azure%20AVM-7B42BC)
![Statut](https://img.shields.io/badge/statut-MVP-orange)

</div>

---

## 💡 Pourquoi

Un LLM laissé seul produit du Terraform **plausible**, mais rien ne garantit qu'il soit correct, conforme aux
conventions maison ou sûr. `terraform-harness` encadre la génération : il **spécialise les rôles**, **charge
les bonnes pratiques au bon moment** et **vérifie systématiquement** la sortie. On passe du *vibe coding* à une
production tracée. Terrain idéal : le Terraform, dont la sortie est **objectivement vérifiable** (elle passe
`validate`/`tflint` ou pas).

Concrètement, il outille la **revue d'architecture** et sépare deux temps : d'abord **valider l'architecture**
(le « quoi »), ensuite **générer le code** (le « comment »).

---

## 🚀 Quick start

```bash
# 1. Prérequis (une seule fois) — installer Terraform sur votre machine
brew install hashicorp/tap/terraform
# + tflint (voir Installation)
```

```text
# 2. Dans Claude Code, installer le plugin
/plugin marketplace add NDA-Partners/terraform-harness-plugin
/plugin install terraform-harness@nda-terraform-harness
/reload-plugins

# 3. Lancer le harness
/generer-terraform
```

Réponds aux questions (destination, environnement…), valide la spec puis le schéma, et récupère ton `.tf`
vérifié. Un exemple complet est dans [`examples/app-web-demo/`](examples/app-web-demo/).

---

## 📦 Installation

### 1. Prérequis

- **[Claude Code](https://code.claude.com)** (l'adaptateur actuel).
- **terraform** et **tflint** — uniquement pour l'étape de vérification statique. Réseau requis pour
  télécharger providers et modules, mais **aucune authentification Azure**.

<details>
<summary>Installer terraform et tflint (macOS)</summary>

```bash
# terraform : absent du core Homebrew depuis le changement de licence HashiCorp
brew install hashicorp/tap/terraform

# tflint : absent du core Homebrew également
brew install tflint          # via le tap officiel tflint
# ou télécharger le binaire : https://github.com/terraform-linters/tflint/releases
```

</details>

### 2. Installer le plugin

```text
/plugin marketplace add NDA-Partners/terraform-harness-plugin
/plugin install terraform-harness@nda-terraform-harness
/reload-plugins
```

La première commande enregistre le **catalogue** (marketplace) dans ta liste locale ; la seconde **installe**
le plugin ; `/reload-plugins` (ou un redémarrage de session) l'active. Après ça, les 4 agents et la skill
`generer-terraform` sont disponibles.

---

## 🛠️ Utilisation

### Lancer le harness : deux façons

1. **La commande dédiée (recommandé)** — tape la skill dans ton prompt, éventuellement suivie de la demande :

   ```text
   /generer-terraform
   ```
   ```text
   /generer-terraform Application web PaaS avec coffre de secrets, stockage de fichiers
   et télémétrie centralisée, environnement de qualification.
   ```
   C'est le point d'entrée explicite : il déroule le workflow complet, de façon fiable et déterministe.

2. **En langage naturel** — décris simplement ton besoin (« génère-moi une archi Terraform pour… »). La skill
   peut se déclencher automatiquement quand la demande correspond, sans garantie. En cas de doute, utilise la
   commande.

### Le déroulé

1. Le harness te **demande où écrire les sorties** (obligatoire, aucun défaut : tu indiques ton propre dossier).
2. Il produit une **spec** de briques AVM → **tu valides**.
3. Il produit un **schéma DrawIO** → **tu valides** (tout ajustement reboucle).
4. Il **génère le `.tf`**.
5. Il lance la **vérification statique** (`fmt` · `validate` · `tflint`) et rend un rapport.

L'humain garde la main aux deux points de validation. Rien n'est déployé.

---

## ⚙️ Comment ça fonctionne

Quatre rôles d'agents spécialisés, orchestrés séquentiellement, avec deux **validations humaines** et une
**boucle de vérification**. La connaissance (constitution, bonnes pratiques Terraform, usage des AVM,
archétypes) vit dans une **ontologie chargée à la demande**.

```mermaid
flowchart TD
    A["📥 Demande d'architecture"]:::io --> B["🤖 architecte-azure<br/>intake · clarification · mapping AVM"]:::agent
    B --> C{"👤 Valider la spec ?"}:::human
    C -->|ajustements| B
    C -->|OK| D["🤖 schema-archi<br/>schéma DrawIO"]:::agent
    D --> E{"👤 Valider le schéma ?"}:::human
    E -->|ajustements| D
    E -->|schéma validé| F["🤖 redacteur-terraform<br/>génération du .tf"]:::agent
    F --> G["🤖 verificateur-terraform<br/>fmt · validate · tflint"]:::agent
    G -->|écarts| F
    G -->|OK| H["✅ Terraform vérifié<br/>100% AVM"]:::io
    classDef agent fill: #DBEAFE, stroke: #2563EB, color: #1E40AF;
    classDef human fill: #FFEDD5, stroke: #F97316, color: #C2410C;
    classDef io fill: #F1F5F9, stroke: #64748B, color: #334155;
```

| Rôle                        | Ce qu'il fait                                                                                  |
|-----------------------------|------------------------------------------------------------------------------------------------|
| 🤖 `architecte-azure`       | ingère la demande, lève les points en suspens, mappe chaque composant sur un AVM → **spec**    |
| 🤖 `schema-archi`           | matérialise la spec en **schéma DrawIO** (nœuds = briques AVM, arêtes = relations)             |
| 🤖 `redacteur-terraform`    | traduit le schéma validé en **code `.tf`** (1 brique AVM = 1 `module`, 1 relation = 1 câblage) |
| 🤖 `verificateur-terraform` | **vérifie** statiquement (`fmt`/`validate`/`tflint`) + conformité à la constitution            |

> Le principe : **valider l'architecture sur un schéma avant d'écrire une ligne de code**. Le visuel rend les
> relations entre ressources lisibles là où le texte les noie. Une fois le schéma validé, la traduction en
> Terraform est quasi déterministe.

<!-- WORKFLOW_SCREENSHOT -->

---

## 🧩 Architecture (portable, multi-outils)

Le dépôt sépare la **substance** de l'**emballage par outil** :

```
core/        source unique et neutre : rôles d'agents, ontologie, workflow
adapters/    cibles générées par outil — aujourd'hui adapters/claude-code/
build/       scripts de génération  (core/ → adapters/<outil>/)
```

Standards pivots d'interopérabilité : **`SKILL.md`** et **`AGENTS.md`**. La sortie générée est commitée (une
installation clone le dépôt tel quel, sans relancer le build).

> 🔜 **Bientôt** : des adaptateurs pour **d'autres outils que Claude Code** (Cursor, Codex via `AGENTS.md`…).
> Aujourd'hui seul l'adaptateur Claude Code est livré ; l'architecture en couches accueille les suivants sans
> réécrire la substance (un `build/build-<outil>.mjs` et un `adapters/<outil>/` de plus).

---

## 🎯 Périmètre et limites

- Cible **Azure + Terraform** via **AVM**.
- **Génération + vérification statique uniquement** : pas de `plan`/`apply`, pas de déploiement, pas de
  Sentinel, pas de reprise d'existant (brownfield).
- MVP : **un archétype** (App Service + Key Vault + Storage).
- **Un seul adaptateur** (Claude Code) pour l'instant.
- Les AVM sont en pré-1.0 : le harness **épingle les versions** et signale la convention **AzAPI**.

---

## 🤝 Contribuer

Contributions bienvenues (archétypes, ontologie, adaptateurs). Règle d'or : **on modifie `core/`, jamais
`adapters/` à la main**, puis on relance le build (`node build/build-claude-code.mjs`). Détails dans
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## 📄 Licence

[Apache-2.0](LICENSE) · voir aussi [`NOTICE`](NOTICE). Développé par **NDA Partners**.
