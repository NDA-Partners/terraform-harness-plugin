# Contribuer à terraform-harness

Merci de votre intérêt. Les améliorations sont bienvenues : nouveaux archétypes, ontologie enrichie,
adaptateurs pour d'autres outils, corrections.

## Principe : `core/` est la source unique

- La substance (rôles d'agents, ontologie, workflow) vit dans **`core/`**, en markdown **neutre**
  (indépendant de tout outil).
- **`adapters/` est généré** depuis `core/` par les scripts de `build/`. **Ne modifiez jamais `adapters/` à
  la main.**
- Après toute modification de `core/`, relancez le build et committez `core/` **et** la sortie régénérée :

  ```
  node build/build-claude-code.mjs
  ```

## Proposer une amélioration

- Ouvrez une **issue** pour discuter d'un changement conséquent avant de coder.
- Pour une petite correction, une **pull request** directe suffit.

## Workflow de pull request

1. Branchez : `git checkout -b amelioration-<sujet>` (ou forkez si vous n'avez pas les droits).
2. Modifiez `core/`, relancez le build, vérifiez l'exemple (voir plus bas).
3. Commit clair, PR contre `main`, avec une description : **quoi**, **pourquoi**, **comment tester**.
4. Revue par un mainteneur avant merge.

## Ajouter un archétype

1. Créez `core/ontologie/archetypes/<nom>.md` (briques AVM, câblage, contraintes, demande type).
2. Déclarez-le dans `build/build-claude-code.mjs` (`KNOWLEDGE_SKILLS`) et dans les `needs` des rôles concernés.
3. Rebuild + vérification.

## Ajouter un adaptateur (Cursor, Codex, ...)

1. Créez `build/build-<outil>.mjs` qui lit `core/` et écrit `adapters/<outil>/` au format de l'outil.
2. Ne changez pas la forme de `core/` : si un adaptateur a besoin d'une information, ajoutez un **champ neutre**
   au frontmatter des rôles, exploité par tous les builds.

## Vérifier l'exemple

Depuis `examples/app-web-demo/terraform/` :

```
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
tflint --init && tflint
```

## Confidentialité

**Aucune donnée confidentielle ou personnelle** dans les contributions : pas de nom de client, de souscription
ou de tenant réels, de secret, d'IP interne. Utilisez des valeurs génériques et des GUID factices (`0000...`).

## Licence des contributions

En contribuant, vous acceptez que votre contribution soit distribuée sous licence **Apache-2.0**.
