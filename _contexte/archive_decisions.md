# Décisions structurantes archivées

- 2026-08-28 : Pont `com_telephone` migré vers le projet Roberto (hôte du serveur + template de
  référence unique). IA_Life devient un projet raccordé (README léger + `/roberto` surveillant
  `messages_ia_life.log` chez Roberto). Serveur/PWA retirés du dépôt IA_Life. Clôt l'action
  ouverte sur l'inclusion git de `ROBERTO/com_telephone`. Détail :
  `D:\ServOMorph\Roberto\roadmap_com_telephone_hub.md`.
- 2026-08-17 : Correctif bug terrain invisible (culling) + relief escarpé + cuvettes de
  spawn + capture d'écran automatisée (`run_screenshot.py`) + skill `synthese-projet`.
- 2026-08-16 : Menu bas + panneaux persos par coin + focus caméra au clic.
- 2026-08-17 : Vitesse de simulation globale, faim/vieillissement/mort, reset complet.
- 2026-08-17 : Cueillette de mûres (ronces), consommation auto, modale "Données du jeu".
- 2026-08-17 : Mode headless + skills `analyse-partie`/`experimentation-headless`.
- 2026-08-17 : Mémoire spatiale des ronciers par personnage + collision physique des ronces.
- 2026-08-17 : Validation manuelle terrain/relief/faim-mort + correctif luminosité (scène
  de jour) ; mode dev (roadmap depuis archivée dans
  `_docs/archives/2026-08-23_roadmap_mode-dev.md`) en cours de construction (Phases 1-2 faites).
- 2026-08-18 : Checklist en jeu (Phase 3 mode dev) + pivot vers un personnage de test
  contrôlable manuellement (remplace F1-F4 seul), voir `_docs/decisions/2026-08-18_*.md`.
- 2026-08-18 : Personnage riggé (Phase 5 graphisme, Blender custom généré par script)
  branché uniquement sur le personnage de test, validé — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- 2026-08-22 : Refonte visuelle des ronces (buisson vert fixe + mûres noires visibles,
  retrait à la cueillette) ; test manuel 5 validé — voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`.
- 2026-08-23 : Le rig Blender reste un outil du personnage de développement ; les quatre
  agents normaux conservent un rendu léger afin de préserver la priorité expérimentale.
- 2026-08-23 : Après échec des bridges tiers, le projet retient provisoirement un bridge
  TCP/JSONL maison pour le premier RL.
- 2026-08-24 : Cadre non historique (île isolée) retenu pour l'identité du jeu, sans ancrage
  temporel — voir `DOCUMENTATION/orientation_contexte.md`.
- 2026-08-24 : `VariableRegistry` devient la source unique des valeurs par défaut/bornes de
  `GameConfig` et `Character` ; bridge RL TCP/JSONL maison validé (épisode complet).
- 2026-08-24 : Les expériences comparables sont bornées par `max_simulation_seconds` et non
  par le temps mural ; la configuration fixe est séparée de `agents.initial_state`.
- 2026-08-25 : `ROBERTO/com_telephone/_commands/com_manager.md` libère désormais le port 5000
  (taskkill) avant tout démarrage/redémarrage de `node`, pour prévenir l'échec EADDRINUSE causé
  par un process orphelin non tracké.
- 2026-08-25 : Phase 4 close — 3 campagnes de référence (`memory_capacity`,
  `resource_scarcity`, `contrasted_profiles`) formalisées, exécutées sur seeds 1/2/3,
  agrégées (`tools/aggregate_results.py`) et graphiques (`tools/plot_campaign.py`, SVG sans
  dépendance). Résultats documentés dans `experiments/README.md`, validés par l'utilisateur.
- 2026-08-25 : Phase 5 close — Inspecteur générique dans `ui_manager.gd` piloté par
  `VariableRegistry` (sélecteur agent/catégorie, tags live/dynamique/nécessite-relancer),
  sliders dupliqués retirés des panneaux de coin, confirmation avant Relancer. Validé
  manuellement par l'utilisateur (tests 15/16).
- 2026-08-25 : ROBERTO (`voice-code-bridge`, hors git) — script de salutation automatique
  retiré (le message "salut" remonte désormais normalement vers l'agent) ; bouton copier
  ajouté sur les bulles de réponse de l'appli mobile. Les deux validés en direct par
  l'utilisateur via le bridge.
- 2026-08-25 : Phase 6 close — communication (partage inconditionnel de position mémorisée),
  coopération (partage de nourriture si faim critique de l'autre) et agressivité (répulsion
  imposée) implémentées, chacune validée par un scénario de simulation dédié — voir
  `_docs/decisions/2026-08-25_phase6-mecaniques-sociales-avancees.md`. Phase 7 débloquée.
- 2026-08-26 : Phase 7 — décideur LLM interchangeable (`scripts/llm_decider.gd`), backend
  Ollama local (`gemma3:1b`, `gemma3:4b` écarté après effondrement), repli automatique sur
  l'automate en cas d'erreur, campagne comparative validée — voir
  `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`.
- 2026-08-26 : ROBERTO — cause racine du bug "injoignable" identifiée et corrigée (clé VAPID
  codée en dur désynchronisée du serveur, pas un cache navigateur) ; reconnexion WebSocket et
  notification push validées en conditions réelles. Convention `!<commande>` (commande à
  distance depuis le téléphone, git compris) créée et inlinée dans `CLAUDE.md` en plus du
  README — un simple renvoi au README s'est avéré insuffisant.

---

- 2026-08-26 : Phase 8 (vision et perception générique) ajoutée à la roadmap en [TODO] ; défaut
  `llm_model` du registre corrigé (`gemma3:4b` -> `gemma3:1b`, désaligné de la décision
  Phase 7).

---

- 2026-08-27 : Phase 8 (vision) close — primitive de perception, vision portée/angle/occlusion,
  `social_radius` absorbé comme cas particulier de la vision (code partagé, équivalence
  démontrée sur les scénarios sociaux Phase 6) — voir
  `_docs/decisions/2026-08-27_phase8-vision-perception.md`.
- 2026-08-27 : Points ouverts Phase 7 clos — prompt few-shot LLM jugé non nécessaire, coopération
  sociale validée statistiquement (5 seeds, jamais nulle).

---

- 2026-08-29 : axe d'évolution retenu — apprentissage individuel intra-vie (1B), table
  `(situation, action) → score` sur la faim ; 1A et 1C écartés à ce stade.
- 2026-08-30 : Phase 1 de la première roadmap apprentissage close : décideur adaptatif engagé,
  correctifs de recherche/cueillette revalidés sur les campagnes de référence.
