# Roadmap — ROBERTO multi-projet (pilotage IA_Life + Appli_TSA_SDI_TDAH depuis le téléphone)

> 2026-08-28 : le pont partagé développé via cette roadmap a été promu et déplacé dans le projet
> Roberto (hôte + template de référence). IA_Life est désormais un projet **raccordé**
> (`ROBERTO/com_telephone/` réduit à un README + `/roberto`). Suite dans
> `D:\ServOMorph\Roberto\roadmap_com_telephone_hub.md`. Statuts de phases à finaliser par `/close`.

## Objectif

Un seul pont ROBERTO (1 serveur Node, 1 STT, 1 TTS, 1 tunnel, 1 PWA) pilotant deux projets
distincts depuis le téléphone, avec un sélecteur de projet dans l'appli. Chaque projet garde sa
session Claude Code, son historique de conversation, son log d'échange et son dossier de captures.

## Architecture cible

- **Serveur hôte** : le pont reste dans `D:\ServOMorph\IA_Life\ROBERTO\com_telephone\`
  (sous git IA_Life, `.env`/`voices`/`messages.log`/`push_subs.json` déjà gitignorés).
  `Appli_TSA_SDI_TDAH` reçoit un déploiement léger qui pointe vers ce serveur, sans copie.
  Alternative écartée pour l'instant : déplacer le serveur dans `D:\ServOMorph\ROBERTO\` commun
  (plus symétrique mais hors des deux dépôts git, migration plus risquée). À revisiter si IA_Life
  est renommé/déplacé.
- **Registre projets** : `voice-code-bridge/server/projects.json` (non versionné) —
  `[{ id, label, racine, log, captures }]`. `id` court (`ia_life`, `tsa`), `label` affiché dans
  la PWA, `racine` = racine absolue du projet, `log` = `logs/messages_<id>.log`,
  `captures` = `<racine>/_docs/captures`.
- **Routage entrant (téléphone → projet)** : la PWA joint `project: <id>` à chaque
  `user.message` / `user.image` / `user.validation`. Le serveur écrit la ligne dans
  `logs/messages_<id>.log` (défaut : premier projet du registre si `project` absent).
- **Routage sortant (projet → téléphone)** : `POST /send` exige `project: <id>` (validé contre le
  registre, 400 sinon). Le serveur inclut `project` dans le payload WS `assistant.text` /
  `assistant.audio` et dans le titre de la notif push (`"<label> · Assistant"`).
- **Affichage PWA** : message entrant dont `project` == projet courant → injecté dans le fil.
  Sinon → pas d'injection, pastille sur le bouton du projet concerné (la push reste envoyée par
  le serveur). Historique localStorage par projet (`chatHistory_<id>`), rechargé au switch.
- **Captures** : résolues par projet depuis le registre (aujourd'hui chemin fixe
  `../../../../_docs/captures`).
- **Surveillance** : chaque session Claude (une par projet) lance son propre Monitor sur
  `logs/messages_<id>.log` et écrit `_commands/monitor_<id>.lock`. `messages.log` global n'est
  plus conservé que pour les lignes `[DEBUG]`.
- **Pré-requis d'usage** : un projet n'est joignable que si sa session Claude Code tourne avec son
  Monitor actif ; sinon le message reste dans le log et seule la push part.

## Phase 1 — Registre projets + config serveur partagé  [TODO]

- Créer `voice-code-bridge/server/projects.json` avec les deux entrées (`ia_life`, `tsa`) et
  l'ajouter au `.gitignore` du bridge.
- Créer `voice-code-bridge/server/logs/` (gitignoré) ; y migrer l'usage de `messages.log`.
- `com_manager.py` : chemins déjà relatifs à `__file__`, aucun changement de structure ;
  vérifier que `_lien_appli()` (AUTH_TOKEN + TUNNEL_URL) reste inchangé.
- Tests : `com_manager.py status` OK ; `projects.json` lu sans erreur au démarrage Node.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Routage serveur multi-projet  [TODO]

- `server.js` :
  - charger `projects.json` au démarrage (échec fatal si absent ou vide).
  - `user.message` / `user.image` / `user.validation` : lire `msg.project`, résoudre l'entrée
    registre, append dans `logs/messages_<id>.log` (défaut premier projet si absent/inconnu +
    ligne `[DEBUG]` de trace).
  - `POST /send` : exiger `project` dans le corps JSON, valider contre le registre (400 +
    message clair sinon), propager `project` dans tous les payloads WS émis.
  - captures : `CAPTURES_DIR` remplacé par une résolution `registre[project].captures`.
  - `messages.log` : réservé aux lignes `[DEBUG]` (push, autoplay, ua, transcription).
- Tests : deux logs distincts alimentés selon `project` ; `POST /send` sans `project` → 400 ;
  `POST /send` avec `project` inconnu → 400 ; image routée dans le bon `_docs/captures`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Sélecteur de projet dans la PWA  [TODO]

- `index.html` : segmented control (un bouton par projet) sous le header, libellés = `label`
  du registre (exposés via un petit endpoint `GET /projects` ou injectés dans `index.html`).
- `app.js` :
  - `currentProject` en localStorage (défaut : premier projet).
  - joindre `project: currentProject` à tous les envois WS.
  - historique : clé `chatHistory_<id>` ; `restoreHistory(id)` au switch après vidage du fil.
  - message WS entrant avec `project` != courant → pas d'injection, `classList` pastille sur le
    bouton projet ; retrait de la pastille au switch vers ce projet.
  - `resetBtn` : ne vide que l'historique du projet courant.
- `sw.js` : inchangé (le titre projet vient du serveur).
- Renseigner `tests_manuels.md` : switch projet, réception croisée (message projet inactif →
  pastille + push, pas d'injection), historiques séparés, `POST /send` des deux côtés.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Déploiement dans Appli_TSA_SDI_TDAH  [TODO]

- Créer `D:\ServOMorph\Appli_TSA_SDI_TDAH\ROBERTO\com_telephone\` (à côté du contenu ROBERTO
  existant `_orchestrateur_ia`, `flux_b_drive` — ne rien vider) :
  - `README.md` : pont hébergé par IA_Life, log surveillé = `messages_tsa.log`, rappel des
    règles (deux canaux, `POST /send` avec `project: "tsa"`, préfixe `!`).
  - `_commands/com_manager_monitor.md` (ou équivalent kit) : (re)lance uniquement le Monitor sur
    `<IA_Life>/ROBERTO/.../logs/messages_tsa.log`, écrit `monitor_tsa.lock` ; ne touche jamais
    aux 3 process partagés.
- Ajouter l'entrée `tsa` dans `projects.json` (racine `D:\ServOMorph\Appli_TSA_SDI_TDAH`).
- `Appli_TSA_SDI_TDAH/.claude/CLAUDE.md` : ajouter la section « Bridge ROBERTO » (mêmes règles
  que IA_Life, adaptées au log `messages_tsa.log` et à `project: "tsa"`).
- `com_manager.md` (hôte, IA_Life) : paramétrer `<projet>` pour cibler le bon log et le bon
  fichier `monitor_<id>.lock` ; l'action `start`/`stop` sur les 3 process reste globale.
- `!close` / `!start` reçus du téléphone : routés vers la session du projet dont le log a reçu
  la ligne (le projet courant de la PWA au moment de l'envoi).
- Mettre à jour `DEPLOYMENTS.md` : ligne v0.3 TSA + note « serveur partagé hébergé par IA_Life ».
- Tests bout-en-bout : depuis le téléphone, switch IA_Life ↔ TSA, un aller-retour vocal complet
  sur chaque projet, vérif que chaque session ne voit que ses propres messages.

## Points ouverts / hors scope

- Nom d'assistant par projet (« Titi » est codé en dur dans `app.js`) — cosmétique, non traité.
- Authentification par projet : le `AUTH_TOKEN` reste unique pour tout le pont.
- creazik_v2 : garde sa copie autonome, non intégré à ce pont partagé.
