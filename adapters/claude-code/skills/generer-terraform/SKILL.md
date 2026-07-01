---
name: generer-terraform
description: Lance le workflow complet du harness : demande d'architecture -> spec -> schéma DrawIO -> code Terraform -> vérification statique, avec validations humaines. À utiliser pour générer de l'infrastructure Terraform Azure.
---

# Workflow du harness

Transforme une demande d'architecture Azure en code Terraform conforme, validé sur un schéma intermédiaire.
Deux temps : d'abord **valider l'architecture** (logique Azure, le « quoi »), ensuite **générer le code**
(Terraform, le « comment »). La validation se fait sur un schéma, car le visuel rend les relations entre
ressources lisibles là où le texte les noie.

**Périmètre** : génération de code + **vérification statique** (`fmt`, `validate`, `tflint`). La chaîne
s'arrête au code `.tf` vérifié en local. Aucun déploiement, aucune souscription Azure requise. Hors
périmètre : `plan`/`apply`, Sentinel, brownfield (aztfexport), intégration MCP Server.

## Flux

L'orchestrateur coordonne la chaîne. Les rôles ne s'appellent pas entre eux. L'humain (l'architecte) valide à
deux points clés : la spec, puis le schéma.

```
demande d'architecture (fournie par l'utilisateur)
   │
   ▼
1. Établir la DESTINATION des outputs (obligatoire, sans défaut, demandée en amont, réutilisée partout)
   │
   ▼
2. Rôle architecte-azure : intake + clarification + mapping AVM → spec d'architecture
   │
   ◇ VALIDATION HUMAINE de la spec
   │
   ▼
3. Rôle schema-archi : spec → <destination>/<archetype>.drawio
   │
   ◇ VALIDATION HUMAINE du schéma  ──(ajustements)──▶ retour à 2 ou 3
   │ schéma validé
   ▼
4. Rôle redacteur-terraform : schéma validé → <destination>/*.tf
   │
   ▼
5. Rôle verificateur-terraform : fmt + validate + tflint + conformité constitution
   │
   ├─ échec ──▶ retour à 4 avec le rapport d'écarts
   └─ succès ─▶ livrable : <destination>/ (code .tf + schéma)
```

## Règle d'orchestration

1. Établir la destination auprès de l'utilisateur, en langage simple et sans jargon (« Dans quel dossier
   veux-tu travailler pour cette demande ? », sans mentionner « .drawio » ni « livrables »). Obligatoire, sans
   valeur par défaut ; réutilisée par la schématisation et la rédaction.
2. Mobiliser le rôle architecte-azure pour produire la spec, puis **demander la validation humaine**.
3. Mobiliser le rôle schema-archi pour produire le `.drawio` dans la destination, puis **demander la
   validation humaine**. Tout ajustement renvoie en 2 ou 3.
4. Sur schéma validé, mobiliser le rôle redacteur-terraform pour générer le `.tf`.
5. Enchaîner systématiquement avec le rôle verificateur-terraform. En cas d'échec, reboucler sur le rédacteur
   avec le rapport.

## Posture et ton (accompagnement)

Le harness s'adresse aussi à des personnes **peu familières de l'IA** et qui **ne connaissent pas ce workflow**.
Adopte une posture d'**assistant qui accompagne**, façon concierge d'hôtel : didactique mais bref, phrases
courtes et claires, **aucun jargon inutile** dans ce qui est montré à l'utilisateur.

À chaque moment clé, dis en une ou deux phrases : **ce qui vient de se passer**, **pourquoi ça compte**, et
**ce qu'on attend** de la personne. Ne récite pas les étapes internes, ne fais pas de pavés.

- **Au démarrage** : accueille en une phrase (à quoi sert l'outil), puis propose — sans l'imposer — soit un
  bref rappel du déroulé pour qui découvre, soit d'entrer directement dans la demande.
- **Destination** : demande simplement où travailler, sans mentionner « .drawio » ni « livrables ».
- **Validation de la spec** : dis en une phrase que tu as traduit le besoin en briques, et invite à confirmer
  ou corriger avant d'aller plus loin.
- **Validation du schéma** : explique que le schéma sert à vérifier ensemble que la demande est bien comprise,
  et invite à confirmer qu'il correspond à la cible visée avant de générer le code.
- **Fin** : annonce simplement que le code est généré et vérifié, et où il se trouve.

Ce sont des **intentions, pas des phrases à recopier** : reformule naturellement, reste court.

## Prérequis

`terraform` et `tflint` installés localement (réseau requis pour télécharger providers et modules, mais aucune
authentification Azure).
