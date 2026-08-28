# com_telephone — raccordement IA_Life au bridge ROBERTO partagé

Ce projet ne contient **plus** de copie du serveur de l'assistant vocal. Le bridge (serveur Node
port 5000, STT port 5001, TTS port 5002, tunnel, PWA) est **hébergé par le projet Roberto** :

    D:\ServOMorph\Roberto\com_telephone\

Un seul pont dessert plusieurs projets. La PWA téléphone affiche un sélecteur de projet ;
chaque message est routé vers le projet choisi (`ia_life`, `tsa`, ...).

> Historique : IA_Life a servi à développer et durcir `com_telephone` (routage multi-projets,
> sélecteur PWA, validations, correctif double-connexion). Le template et l'hébergement ont été
> promus dans Roberto le 2026-08-28 (cf. `Roberto\roadmap_com_telephone_hub.md`).
> Le dossier `voice-code-bridge/` restant ici est mort (ignoré par git), conservé le temps de la
> migration puis supprimable.

## Ce dont IA_Life a besoin

- **Les 3 process partagés doivent tourner.** Ils sont démarrés côté Roberto :
  `py -3.11 D:\ServOMorph\Roberto\com_telephone\_commands\com_manager.py start`.
  Rien à lancer depuis IA_Life.
- **Une surveillance du log IA_Life.** La session Claude Code IA_Life doit surveiller en continu
  `D:\ServOMorph\Roberto\com_telephone\voice-code-bridge\server\logs\messages_ia_life.log`.
  Commande dédiée : `/roberto` (cf. `.claude/commands/roberto.md`) — (re)lance ce Monitor et
  écrit le `task_id` dans `_commands/monitor_ia_life.lock` de ce dossier.

## Règles

- **Deux canaux étanches.** Toute réponse à un message venu du log doit repartir par
  `POST http://127.0.0.1:5000/send`, même si elle est déjà écrite dans la conversation Claude Code.
- **Corps `POST /send` : clés `text` et `project`.** La clé du message est `text` (pas `message`,
  pas `body`). Tout `POST /send` doit contenir `"project": "ia_life"` et un `"text"` non vide —
  sinon HTTP 400. `POST /send` n'est accessible que depuis `127.0.0.1`.
- **Questions à l'utilisateur.** Dès que le bridge est actif, toute décision/choix/validation
  destinée à l'utilisateur passe par `POST /send` (avec `options` / `recommended` si choix fermé),
  jamais par une question bloquante terminal.
- **Style oral.** Le message est écouté (TTS), pas lu : phrases courtes, une idée à la fois, pas de
  chemins de fichiers ni de markdown brut.
- **Commandes `!<nom>`.** Un message téléphone commençant par `!` (ex. `!close`) est une instruction
  directe : appliquer `.claude/commands/<nom>.md` d'IA_Life, reste du message = arguments, actions
  git incluses sans confirmation terminal supplémentaire (l'envoi depuis le téléphone vaut
  confirmation). Le bilan de fin de procédure doit quand même repartir par `POST /send`. Commande
  inconnue : le signaler par `POST /send` plutôt que deviner.

## Exemple `POST /send`

```
curl -X POST http://127.0.0.1:5000/send -H "Content-Type: application/json" -d '{
  "text": "Tests verts, la branche est prete.",
  "project": "ia_life"
}'
```

Choix fermé :

```
curl -X POST http://127.0.0.1:5000/send -H "Content-Type: application/json" -d '{
  "text": "Je pars sur l option A. Tu confirmes ?",
  "project": "ia_life",
  "options": ["Oui, option A", "Non, option B"],
  "recommended": "Oui, option A"
}'
```
