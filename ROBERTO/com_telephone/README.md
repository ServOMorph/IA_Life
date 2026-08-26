# com_telephone

## Objectif
Assistant vocal distant pour Claude Code : dialoguer par la voix depuis un téléphone avec une
session Claude Code tournant sur le PC, sans clavier ni intervention manuelle côté PC pendant la
conversation. Prototype construit à partir de `specification_assistant_vocal_claude_code.pdf`.

## Structure
- `specification_assistant_vocal_claude_code.pdf` : spécification fonctionnelle et technique d'origine.
- `voice-code-bridge/` : implémentation — PWA mobile (chat + écran d'écoute vocale), serveur Node
  (HTTP + WebSocket), STT Whisper local, TTS Piper local. Voir `voice-code-bridge/README.md` pour
  l'installation et le détail des composants.
- `_commands/` : `com_manager.py` (+ `com_manager.md`, commande Claude Code) pour démarrer/arrêter/
  vérifier les 3 processus serveur en une seule commande, avec activation automatique de la
  surveillance du fichier d'échange (`messages.log`).

## Fonctionnement
Le téléphone ouvre la PWA (accès distant via un tunnel déjà configuré côté utilisateur — Cloudflare
Tunnel, Tailscale, etc.), écrit ou parle un message. Le serveur journalise chaque message dans
`voice-code-bridge/server/messages.log`. Un agent Claude Code surveille ce fichier en continu et
répond via `POST /send` (texte + audio synthétisé), renvoyé au téléphone et lu automatiquement — le
tout en boucle conversationnelle continue (écoute → réponse → réécoute).

## Lancement rapide
```
python _commands/com_manager.py start
```
Démarre les 3 processus (STT, TTS, puis Node) et active la surveillance de `messages.log`.

## Règle absolue : deux canaux distincts
La conversation Claude Code (terminal/IDE) et l'appli téléphone sont deux canaux séparés. Répondre
dans l'un ne transmet rien à l'autre. Dès qu'un message vient de `messages.log` (donc du téléphone),
la réponse doit systématiquement passer aussi par `POST /send` — même si elle est déjà écrite dans
la conversation Claude Code. Oubli déjà constaté le 2026-08-24 (correctif scroll répondu uniquement
dans Claude Code, jamais reçu côté téléphone).

## Commandes à distance (préfixe `!`)
Un message reçu depuis le téléphone commençant par `!` est une instruction directe, pas un message
conversationnel : `!<nom>` (ex. `!close`, `!start`) signifie appliquer la procédure du fichier
`.claude/commands/<nom>.md` correspondant, exactement comme si `/<nom>` avait été tapé dans le
terminal — le reste du message après `!<nom>` fait office d'arguments. Si `<nom>` ne correspond à
aucun fichier commande existant, le signaler par `POST /send` plutôt que de deviner une intention.

Autorisation permanente actée le 2026-08-26 : les actions git (commit/push) prévues par une
procédure ainsi déclenchée s'exécutent sans confirmation terminal supplémentaire — le fait d'envoyer
`!<commande>` depuis le téléphone vaut confirmation. Le résultat (bilan de fin de procédure) doit
quand même être renvoyé sur le téléphone via `POST /send`, conformément à la règle des deux canaux.

## Style des réponses (POST /send)
L'utilisateur écoute la réponse (TTS), il ne la lit pas. Chaque message envoyé via `POST /send`
doit être reformulé pour l'oral, pas recopié depuis un fichier ou un résultat d'outil :
- Une idée à la fois, phrases courtes.
- Aucune info superflue (chemins de fichiers, formatage markdown, listes à puces brutes,
  détails techniques non demandés).
- Si plusieurs éléments à annoncer, les résumer en une phrase de synthèse plutôt que tout lister.

## Règle absolue : choix rapides via l'appli quand le bridge est actif
Dès que les 3 process du bridge sont actifs (démarrés via `com_manager.md`), toute question de
décision destinée à l'utilisateur (choix entre plusieurs options, validation d'une approche) doit
être posée via l'appli téléphone plutôt que via une question bloquante dans le terminal Claude
Code. Utiliser `POST /send` avec `options` (tableau de libellés courts) et `recommended` (le
libellé recommandé, mis en avant visuellement) ; annoncer aussi la recommandation dans `text`.
L'utilisateur tape sur un bouton, la réponse remonte dans `messages.log` comme un message normal.
Vaut aussi pour une question fermée oui/non : passer `"options": ["Oui", "Non"]` plutôt que
laisser l'utilisateur taper la réponse. Confirmé fonctionnel et validé par l'utilisateur le
2026-08-25 après un cas réel (choix de mécaniques de jeu pour ia_life, phase 6).

```
curl -X POST http://127.0.0.1:5000/send -H "Content-Type: application/json" -d '{
  "text": "Communication : partage de position mémorisée entre agents ? Je recommande oui.",
  "options": ["Oui, partage de position", "Autre définition"],
  "recommended": "Oui, partage de position"
}'
```

## Ajouts dans CLAUDE.md
`.claude/CLAUDE.md` (racine du projet, injecté automatiquement dans le contexte à chaque tour,
contrairement à ce README qui doit être relu volontairement) référence désormais ce dossier.
Liste de ce qui y a été ajouté à cause de ROBERTO :

- 2026-08-26 : section "Bridge ROBERTO" (dans "Spécificités projet") — rappelle que toute
  question/réponse destinée à l'utilisateur doit passer par `POST /send` dès que les 3 process
  du bridge sont actifs, et renvoie ici pour le détail. Ajoutée après deux oublis constatés dans
  la même session malgré la règle déjà écrite plus haut dans ce fichier (sections "Règle
  absolue" ci-dessus) — la règle seule dans ce README n'a pas suffi.

## État
Fonctionnel de bout en bout, testé en conditions réelles (iPhone/Safari). Pas d'authentification sur
l'UI à ce stade — ne pas exposer durablement sans en ajouter une.
