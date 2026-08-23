# Signals — ia_life (MAJ 2026-08-23)

## Actions ouvertes

- [P1|ouvert] Choisir l'identité de contexte du jeu : comparer le Paléolithique ancien à
  au moins un cadre non historique, sans introduire de contenu avant décision.
  fait quand: un choix est documenté avec ses conséquences de gameplay et ses limites.
  réf: DOCUMENTATION/orientation_contexte.md, roadmap_experimentation.md (Phase 0)
- [P1|ouvert] Formaliser les trois campagnes de référence (mémoire, rareté, profils) sur
  plusieurs seeds et produire leurs graphiques de comparaison.
  fait quand: les trois campagnes sont exécutables, reproductibles et agrégées.
  réf: roadmap_experimentation.md (Phase 4), tools/run_campaign.py
- [P2|ouvert] Réconcilier la documentation et la roadmap de la zone design avec les
  validations graphiques déjà réalisées.
  fait quand: DESIGN/_contexte/signals.md et DESIGN/roadmap_graphisme.md reflètent l'état réel.
  réf: DESIGN/_contexte/, DESIGN/roadmap_graphisme.md

## Contexte chaud

- Le personnage riggé reste exclusivement celui du mode dev ; les quatre agents de
  simulation conservent volontairement leurs représentations légères.
- Les fichiers DESIGN modifiés et _docs/Analyse du projet/ sont préexistants ou relèvent
  d'une autre zone : ils ne doivent pas être inclus dans le commit ia_life.
- Écart connu : scripts/check_kit.py est absent ; le contrôle d'intégrité dédié ne peut
  pas être lancé tant qu'il n'est pas fourni ou remplacé.

## Dernière session (2026-08-23)

# Session du 2026-08-23

## Décisions prises
- Le rig reste limité au personnage de développement ; le laboratoire privilégie les agents légers.
- Le projet prépare un contexte historique possible sans l'adopter avant comparaison avec une autre identité.

## Livrables produits ou modifiés
- roadmap_experimentation.md : feuille de route, métriques sociales et smoke test mis à jour.
- scripts/experiment_config.gd, character.gd, main.gd : validation sociale, hash/revision et métriques.
- tools/run_smoke_tests.py, aggregate_results.py : contrôle reproductible et rapports sociaux.
- DOCUMENTATION/ : index et cadre de décision du contexte.

## Hypothèses validées / invalidées
- VALIDE : le suivi et l'évitement sont activables, mesurés et exportés en headless.
- VALIDE : une configuration invalide est rejetée et chaque run laisse un résumé vérifiable.
- EN ATTENTE : choix du contexte historique et campagnes statistiques multi-seeds.

## Prochaine étape exacte
Formaliser les trois campagnes de référence, puis produire leur tableau et graphiques comparatifs.

## Question bloquante pour la session suivante
Aucune.
