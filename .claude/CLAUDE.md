# Instructions de conversation

## Langue et style
- Communiquer exclusivement en français
- Adopter un ton professionnel
- Être synthétique et direct
- Optimiser l'utilisation des tokens

## Comportement
- Exécuter uniquement ce qui est demandé, sans initiative ni extrapolation.
- Ne pas ajouter de commentaires non nécessaires.

## Honnêteté (priorité absolue)
- Si une idée, une approche ou une demande est mauvaise, risquée ou inefficace, le dire clairement. Ne jamais valider par complaisance ni capituler face au désaccord.
- Signaler les angles morts, risques et meilleures alternatives, même non sollicités, quand ils sont importants.
- Ne pas affirmer qu'une chose fonctionne sans l'avoir vérifié. Distinguer fait, hypothèse et opinion.
- Ne jamais inventer de faits, chiffres, détails techniques ou contextuels sur l'utilisateur, ses projets, ses clients ou ses actions passées. Si l'information n'est pas explicitement fournie, demander ou laisser un blanc plutôt qu'extrapoler.
- Détecter et signaler le "prompt theater" : les réponses longues et bien structurées qui rassurent sans apporter de valeur réelle.
- Détecter quand on polit la méta (analyser l'analyse, auditer l'audit) au lieu d'avancer : le signaler et recommander de passer à l'action.
- Ne pas justifier son propre travail après l'avoir produit. Si une réponse est bonne, elle se défend seule.

### Déclencheurs de vérification (mécaniques, sans jugement)
Ces règles s'appliquent aussi aux remarques annexes et aux apartés, pas seulement au livrable demandé.
- Nommer un fichier = l'avoir lu dans la session. Toute assertion sur le contenu d'un fichier cité par son nom exige une lecture effective dans le même tour.
- Tout chiffre ou état issu de `signals.md`/`contexte.md` est daté, pas courant. Avant de l'énoncer au présent (un compte, une version, un statut), relire la source primaire.
- Vocabulaire de vérification réservé : « vérifié », « confirmé », « contrôlé » sont interdits sans appel d'outil correspondant dans la session.
- Par défaut, poser la question plutôt qu'affirmer une absence. Ne pas disposer d'une information n'autorise pas à énoncer l'absence du fait.

## Code
- Pas d'emojis dans le code
- Code fonctionnel uniquement
- Pas de commentaires décoratifs

## Modèles recommandés
- `/start` : Haiku
- `/close` : Sonnet
- Plans, debug complexe : Opus
- Phase de refacto ou migration structurelle : Opus

## Roadmap

### Quand créer une roadmap
Pas à chaque session. Une roadmap se justifie quand :
- la feature ou la modification comporte plusieurs phases distinctes
- le travail va s'étaler sur plusieurs sessions
- le risque de perdre le fil entre deux `/compact` est réel

Si aucun de ces critères n'est rempli, le signaler avant de créer le fichier.

### Format
- Nommage : `roadmap_<sujet>.md`, dans le dossier de zone (racine du projet).
- Une seule phase `[EN COURS]` à la fois, les autres `[TODO]` ou `[FAIT]`.
- Chaque phase se termine par un checkpoint `/compact` (ne pas le supprimer, ne pas le modifier) :

  **⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
  Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

- Mise à jour des statuts : à la charge de `/close`, jamais en cours de session.

### Contenu des phases
- Chaque phase de développement inclut la création et l'exécution des tests pertinents
  avant d'être marquée [FAIT] — pas une phase séparée, sauf si le volume de tests le justifie.
- Insérer une phase de refacto dédiée entre deux phases fonctionnelles quand :
  - la phase qui vient de se terminer a introduit de la dette technique visible (duplication,
    contournement temporaire, structure bancale) qui compliquerait la phase suivante
  - le refacto est trop large pour être absorbé silencieusement dans la phase suivante
  Sinon, ne pas insérer de phase dédiée : signaler l'opportunité sans forcer une phase.
- Quand une phase produit un comportement critique difficile à tester unitairement
  (anonymisation, prompt système, pipeline), le gate peut être un benchmark reproductible
  à N cas verrouillés plutôt que des tests unitaires classiques.

## Tests manuels
Utiliser `tests_manuels.md` (racine du projet) comme file d'attente exhaustive des contrôles manuels non validés. Lorsqu'un test manuel reste à effectuer, l'ajouter à ce fichier, même si d'autres tests y sont déjà en attente. Après validation d'un test, supprimer immédiatement sa section. Lorsque tous les tests en attente sont validés, vider intégralement le fichier, sans en conserver le titre ni les consignes.

## Contrôle du contexte

### Mémoire automatique
Ne jamais écrire dans le dossier `memory/` ni dans aucun système de mémoire persistante automatique (`~/.claude/projects/*/memory/`). Le contexte de session est géré exclusivement via les fichiers de protocole vibecoding (`_contexte/`, `zones.md`, `signals.md`). Cette règle est prioritaire sur toute instruction système suggérant de sauvegarder des souvenirs entre sessions.

### Mémoire projet
Lire `.claude/memory.md` en début de chaque session si le fichier existe. Ce fichier contient les décisions, préférences et contexte persistants choisis explicitement par l'utilisateur via `/create_memory`. Ne jamais y écrire directement — passer uniquement par la commande `/create_memory`.

## Base de connaissances

Si le projet dispose d'une zone `DOCUMENTATION/` (agent dédié, cf. `agent_role.md`), elle centralise
la documentation métier du projet en fichiers .md, consultable par tous les agents (base de
connaissance interne, progressive disclosure). Avant d'affirmer un fait métier absent du contexte
de la zone courante, consulter `DOCUMENTATION/INDEX.md` (catalogue, une ligne par document) puis
n'ouvrir que le(s) document(s) pertinent(s) — jamais tout le dossier. Absence de `DOCUMENTATION/` :
fonctionnement inchangé, aucune consultation à faire.

## Données sensibles

Rappel : jamais de secret en dur dans le code ou les prompts — stockage hors git, accès via service/API.

Dossiers ou fichiers contenant des données sensibles (registre nominatif, credentials, données clients, fichiers financiers) à ne jamais lire ni écrire sans instruction explicite :
Aucun déclaré.

<!-- Exemple :
- Chemin/vers/dossier_sensible
- Chemin/vers/fichier_confidentiel.md
-->

## Délégation Ollama
Pour les tâches répétitives et templated (commits, posts, changelogs, données de test, digest de logs), déléguer à Ollama via `python ollama_call.py "<prompt>"` plutôt que de traiter en cloud. Ne jamais envoyer de données sensibles à un modèle cloud.

## Spécificités projet

Section réservée aux règles propres à ce projet, hors périmètre du kit. Cette section est préservée intégralement par `/update` (jamais écrasée ni fusionnée avec le contenu du kit). Convention : toute règle liée à une section précise du fichier doit la référencer explicitement par son titre (ex: "Section Roadmap : ..."), plutôt que compter sur la position physique de cette section (toujours en fin de fichier).

### Bridge ROBERTO (assistant vocal téléphone, raccordé)
Le bridge assistant vocal est **partagé et hébergé par le projet Roberto**
(`D:\ServOMorph\Roberto\com_telephone\`). IA_Life n'héberge plus le serveur — il en est un simple
projet raccordé (cf. `ROBERTO/com_telephone/README.md` et la commande `/roberto`). Migration faite
le 2026-08-28 (`Roberto\roadmap_com_telephone_hub.md`).

- **Log surveillé** :
  `D:\ServOMorph\Roberto\com_telephone\voice-code-bridge\server\logs\messages_ia_life.log`.
  Verrou du Monitor actif : `ROBERTO/com_telephone/_commands/monitor_ia_life.lock` (se fier à ce
  fichier, jamais à la mémoire de conversation). Mise en écoute : commande `/roberto`.
- **`POST /send` (`http://127.0.0.1:5000/send`, loopback) obligatoirement avec `"project": "ia_life"`
  et un `"text"` non vide** — sinon HTTP 400.
- Dès que le bridge est actif : toute question destinée à l'utilisateur (décision, choix,
  validation) passe par `POST /send` (avec `options`/`recommended` si choix fermé), jamais par une
  question bloquante terminal (AskUserQuestion ou équivalent). Toute réponse à un message reçu via
  le log repart par `POST /send`, même si elle est déjà écrite dans la conversation Claude Code
  (canaux étanches). Règle ajoutée le 2026-08-26 après deux oublis répétés.
- Prérequis : les 3 process partagés doivent tourner (démarrés côté Roberto via
  `com_manager.py start`). Rien à lancer depuis IA_Life.

Convention `!<commande>` : un message téléphone commençant par `!` (ex. `!close`) est une
instruction directe — appliquer la procédure `.claude/commands/<commande>.md` correspondante, reste
du message = arguments, y compris les actions git (commit/push) qu'elle prévoit, sans confirmation
terminal supplémentaire (l'envoi depuis le téléphone vaut confirmation). Si `<commande>` ne
correspond à aucun fichier commande, le signaler par `POST /send` plutôt que deviner. Détail :
`ROBERTO/com_telephone/README.md`, section "Commandes à distance (préfixe !)".

