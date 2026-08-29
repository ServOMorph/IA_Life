# Session du 2026-08-17

## Décisions prises
- Cueillette de mûres (ronces), consommation auto, modale "Données du jeu" (proposé)
- Mode headless + skills `analyse-partie`/`experimentation-headless` (proposé)
- Mémoire spatiale des ronciers par personnage, capacité 0-10 (proposé)
- Collision physique ajoutée aux ronces, en plus de l'Area3D de détection (proposé)
- Plafond de vitesse headless x80 documenté ; correction collision de nommage des logs

## Livrables produits ou modifiés
- scripts/game_config.gd, ronce.gd, game_logger.gd : créés
- scripts/character.gd, main.gd, ui_manager.gd, free_camera.gd : modifiés
- run_headless.py : créé
- .claude/skills/analyse-partie/, experimentation-headless/ : créés
- _docs/decisions/*.md : mis à jour (2 décisions enrichies d'amendements)

## Hypothèses validées / invalidées
- VALIDE (empirique headless) : la vitesse de jeu n'altère pas l'issue une fois les
  mécaniques indexées sur `time_scale`
- VALIDE (empirique headless, 8 runs x50) : mémoire + collision physique des ronces
  n'introduisent pas de régression sur cueillette/survie
- EN ATTENTE : aucune validation manuelle en jeu (`python run.py`) reçue cette session ->
  les décisions restent au statut "proposé"

## Prochaine étape exacte
Retester manuellement en jeu (`python run.py`) l'ensemble des mécaniques ronces/mémoire,
puis valider/invalider les décisions dans `_docs/decisions/`.

## Question bloquante pour la session suivante
Aucune

---

# Session du 2026-08-17

## Décisions prises
- Validation manuelle en jeu du terrain/relief/cuvettes de spawn, de la faim/
  vieillissement/mort et de la vitesse de simulation ; clignotement de texture d'herbe
  non reproduit (considéré résolu)
- Construction du mode dev (`_docs/archives/2026-08-23_roadmap_mode-dev.md`) pour rendre observables à la demande
  les mécaniques bloquées en observation directe (cueillette isolée, 4 personnages
  simultanés) : `run_dev.py`, raccourcis clavier, UX en jeu
- Correction du bug "scène de nuit" (ciel/lumière/exposition), vérifiée par capture
  d'écran automatisée avant/après

## Livrables produits ou modifiés
- `_docs/archives/2026-08-23_roadmap_mode-dev.md` : créé (Phases 1 et 2 [FAIT], Phases 3-4 [TODO])
- `run_dev.py` : créé
- `scripts/main.gd` : raccourcis dev (Espace/N/H/E/F1-F4), correctif éclairage jour
- `scripts/ui_manager.gd` : bandeau "MODE DEV" + indicateur "Temps gelé"
- `tests_manuels.md` : items validés retirés ; reste 2 tests BLOQUÉS + 1 bug connu
- `_docs/decisions/2026-08-17_ronces-mures-donnees-jeu.md`,
  `_docs/decisions/2026-08-17_terrain-relief-procedural.md` : commentaires mis à jour

## Hypothèses validées / invalidées
- VALIDE : relief, cuvettes de spawn, faim/vieillissement/mort, vitesse de simulation
- INVALIDE : luminosité (scène de nuit) -> corrigée (ciel/lumière/exposition), vérifiée
  par capture d'écran, en attente de confirmation utilisateur en jeu
- EN ATTENTE : bascule plein/vide des ronces, comportement des 4 personnages simultanés,
  cueillette/consommation/mémoire/collision (items 3-12), bug enfoncement dans le sol

## Prochaine étape exacte
Phase 3 de `_docs/archives/2026-08-23_roadmap_mode-dev.md` : UX de checklist en jeu.

## Question bloquante pour la session suivante
Aucune

---

# Session du 2026-08-18

## Décisions prises
- Rig personnage (Phase 5, `roadmap_graphisme.md`) généré via Blender headless (script
  reproductible), branché uniquement sur le personnage de test — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- Personnage de test contrôlable (F5/ZQSD) confirmé fonctionnel après usage intensif cette
  session — statut de la décision passé à validé.
- Checklist en jeu retravaillée (sélection individuelle par test, état persisté, masquage
  des tests validés) ; réglages du jeu persistés sur disque (`GameConfig`).

## Livrables produits ou modifiés
- `tools/blender/build_character.py`, `assets/models/character.glb` : créés (rig 10 os,
  animations Idle/Walk/Death)
- `scripts/main.gd`, `character.gd` : rig branché sur le perso test, touche K (tuer le
  perso test), touche G (faim haute), Shift+F1-F4 (téléport au contact d'une ronce)
- `scripts/ui_manager.gd`, `game_config.gd` : refonte checklist, persistance des réglages
- `scripts/free_camera.gd` : correctif pitch orbite + clamp au sol
- `tests_manuels.md` : items 1-4 et rig Phase 5 validés et retirés ; items 5, 6, 8-12
  enrichis d'étapes précises
- `_docs/decisions/` : 2 fichiers mis à jour/créés (statuts validé)

## Hypothèses validées / invalidées
- VALIDE : contrôle clavier du personnage de test fonctionnel
- VALIDE : rig Phase 5 (Idle/Walk/Death) sur le personnage de test
- VALIDE : cueillette/consommation de base, bascule ronce, animation procédurale 4 persos
- EN ATTENTE : items 5, 6, 8-12 de `tests_manuels.md`

## Prochaine étape exacte
Reprendre la checklist en jeu (touche T) pour les items 5, 6, 8-12 ; trancher l'extension
du rig aux 4 personnages normaux.

## Question bloquante pour la session suivante
Aucune

---

# Session du 2026-08-23

## Décisions prises
- Les bridges tiers sont écartés selon le coupe-circuit ; le bridge TCP/JSONL maison devient le chemin actif.

## Livrables produits ou modifiés
- DOCUMENTATION/RL/01_voie_rapide_PPO_partage.md : voie PPO corrigée et renommée.
- scripts/rl_bridge.gd, scripts/main.gd, scripts/character.gd, rl/client_random.py : première intégration TCP/JSONL, non validée en épisode.

## Hypothèses validées / invalidées
- VALIDE : les scripts RL sont analysés sans erreur par Godot après correction des erreurs de typage et de nom de méthode.
- INVALIDE : les bridges tiers sont exploitables immédiatement sur cette machine ; pivot TCP/JSONL maison.
- EN ATTENTE : démarrage effectif du serveur et épisode random complet.

## Prochaine étape exacte
Lancer Godot en mode RL au premier plan, identifier pourquoi `RLBridge.start()` n'est pas atteint, puis relancer deux fois `python rl/client_random.py --max-steps 12` avec la même seed.

## Question bloquante pour la session suivante
Aucune

---

# Session du 2026-08-26

## Décisions prises
- Défaut `llm_model` du registre corrigé (`gemma3:4b` -> `gemma3:1b`), aligné sur la décision
  Phase 7 déjà actée mais jamais reportée dans `variable_registry.gd`.
- Phase 8 (Vision et perception générique de l'environnement) ajoutée à la roadmap en [TODO],
  avec recommandation de la traiter avant d'élargir les campagnes LLM.

## Livrables produits ou modifiés
- `scripts/variable_registry.gd` : défaut `llm_model` corrigé (ligne 37).
- `tests_manuels.md` : vidé intégralement (tous les tests en attente validés).
- `roadmap_experimentation.md` : Phase 8 ajoutée, section "Prochain sprint recommandé" mise à
  jour.
- `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md` : commentaire ajouté sur le
  correctif du défaut `llm_model`.

## Hypothèses validées / invalidées
- VALIDE : affichage `decider_type`/`llm_*` dans l'Inspecteur conforme à l'attendu (test manuel
  Phase 7).
- INVALIDE : hypothèse que le défaut `llm_model` du registre était déjà aligné sur `gemma3:1b`
  -> resté sur `gemma3:4b`, corrigé.

## Prochaine étape exacte
Décider de l'ordre entre la Phase 8 (vision) et les points ouverts Phase 7 (few-shot, campagne
coopération multi-seeds) ; démarrer la Phase 8 si priorité confirmée.

## Question bloquante pour la session suivante
Aucune.

---

# Session du 2026-08-27

## Décisions prises
- Phase 8 (vision) complétée : direction de référence = orientation visuelle, priorité roncier
  visible > mémorisé, mémorisation par vision. `social_radius` absorbé comme cas particulier de
  la vision (code partagé), équivalence stricte démontrée sur les 3 scénarios Phase 6.
- Prompt few-shot LLM jugé non nécessaire (`gemma3:1b` stable avec le prompt étendu).
- Coopération validée statistiquement (5 seeds, partage de nourriture jamais nul).

## Livrables produits ou modifiés
- `scripts/character.gd`, `ronce.gd`, `baseline_decider.gd`, `llm_decider.gd`, `main.gd`,
  `variable_registry.gd`, `ui_manager.gd` : Phase 8.
- `tools/aggregate_results.py`, `tools/run_manual_checks.gd` (6 nouveaux tests vision).
- `experiments/vision_*.json` (4 scénarios), `campaigns/vision_range_campaign_v1.json`,
  `campaigns/social_cooperation_multiseed_v1.json` : créés.
- `_docs/decisions/2026-08-27_phase8-vision-perception.md` : créé ; deux décisions Phase 6/7
  complétées d'un commentaire de clôture.

## Hypothèses validées / invalidées
- VALIDE : coopération reproductible sur 5/5 seeds ; `gemma3:1b` stable avec le prompt étendu.
- INVALIDE : mémorisation par vision à chaque frame -> boucle infinie si plus d'entités visibles
  que `memory_capacity` -> corrigée (une fois par apparition), test de non-régression ajouté.
- INVALIDE (mineure) : distance horizontale pour l'absorption sociale -> corrigée (distance 3D
  préservée pour le social via un paramètre `flatten_vertical` sur `_perceive`).

## Prochaine étape exacte
Décider de la Phase 9 (aucune définie) ou d'un autre axe ; sinon traiter les points restants hors
code (inclusion git de `ROBERTO/com_telephone`, dédoublonnage `push_subs.json`).

## Question bloquante pour la session suivante
Aucune.

---

# Session du 2026-08-28

## Décisions prises
- Le pont `com_telephone` est migré vers le projet Roberto (hôte du serveur + template de
  référence unique). IA_Life devient un projet raccordé : plus de serveur, README de
  raccordement + commande `/roberto`.
- `.env` d'IA_Life réutilisé tel quel sur Roberto → lien appli et abonnements push préservés.
- Reste de `ROBERTO/com_telephone/` : serveur/PWA/com_manager retirés du dépôt, reliquats
  gitignorés → clôt l'action ouverte [P2] sur l'inclusion git du bridge.

## Livrables produits ou modifiés
- `ROBERTO/com_telephone/README.md` : réécrit (raccordement au pont Roberto).
- `.claude/commands/roberto.md` : créé. `.claude/CLAUDE.md` : section « Bridge ROBERTO » réécrite.
- `ROBERTO/com_telephone/.gitignore`, `_commands/.gitignore` : créés / mis à jour.
- Serveur + PWA + `com_manager` retirés (`git rm --cached` + suppression disque, sauf 1 dossier vide).
- Commits : `866a48c`, `852e4a2`.

## Hypothèses validées / invalidées
- VALIDE : bascule du pont vers Roberto sans changement de lien appli ni perte des push.
- EN ATTENTE : tests manuels téléphone (aller-retour vocal par projet) — `Roberto/tests_manuels.md`.

## Prochaine étape exacte
Côté IA_Life : rien de bloquant (Phase 9 non définie). Hors zone : finir les tests manuels du
pont depuis le téléphone, supprimer le dossier vide `voice-code-bridge/`.

## Question bloquante pour la session suivante
Aucune.
