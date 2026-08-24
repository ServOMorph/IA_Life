# Signals — ia_life (MAJ 2026-08-23)

## Actions ouvertes

- [P1|ouvert] Obtenir un épisode complet via le bridge TCP/JSONL et le client aléatoire.
  fait quand: `python rl/client_random.py` termine un épisode sans NaN et journalise reward, terminated et truncated.
  réf: scripts/rl_bridge.gd, scripts/main.gd, scripts/character.gd, rl/client_random.py
- [P1|ouvert] Choisir l'identité de contexte du jeu : comparer le Paléolithique ancien à au moins un cadre non historique.
  fait quand: un choix est documenté avec ses conséquences de gameplay et ses limites.
  réf: DOCUMENTATION/orientation_contexte.md, roadmap_experimentation.md (Phase 0)
- [P1|ouvert] Formaliser les trois campagnes de référence sur plusieurs seeds et produire leurs graphiques.
  fait quand: les trois campagnes sont exécutables, reproductibles et agrégées.
  réf: roadmap_experimentation.md (Phase 4), tools/run_campaign.py

## Contexte chaud

- Le mode `IA_LIFE_RL_MODE` n'ouvre pas encore le port 11008 ; le client reçoit `ConnectionRefused`.
- GDRL a échoué côté bridge Python (WinError 32) ; `godot-native-rl` a échoué par crash Godot (signal 11).
- Les fichiers DESIGN modifiés et _docs/Analyse du projet/ sont préexistants ou d'une autre zone : ne pas les committer.
- Écart connu : scripts/check_kit.py est absent.

## Dernière session (2026-08-23)

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
Aucune.
