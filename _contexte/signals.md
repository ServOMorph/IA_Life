# Signals — ia_life (MAJ 2026-09-10)

## Actions ouvertes

- [P1|ouvert] Évaluer une alternative au contournement stateful actuel, ou abandonner l'axe danger.
  fait quand: une décision documentée retient une alternative bornée ou clôt l'axe ; aucune seed réservée n'est ouverte avant le gate de calibration.
  réf: `_docs/decisions/2026-09-10_contournement-stateful.md`, `roadmap_environnement_apprenable_v3.md` (Phase 3).
- [P2|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute campagne.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P3|dormant] Axe apprentissage v2 suspendu pendant la validation de l'environnement v3.
  fait quand: Phases 0-5 v3 [FAIT] et gate réservé Phase 4 passé.
  réf: `roadmap_environnement_apprenable_v3.md`, `roadmap_apprentissage_v2.md`.

## Contexte chaud

- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- Les logs v2 comptent 7 timeouts sur 20 détours ; les positions deviennent constantes avant délai, compatible avec un blocage par collision. V3 propose un unique changement de côté après 2 s sans progression, sans campagne lancée.
- L'évaluateur de calibration comparait `eviter` à `ignorer` par inversion locale : corrigé et couvert par deux tests Python. Les anciens rapports corrigés restent sous le gate.
- `IA_LIFE_HEADLESS_FIXED_FPS=60` accélère les campagnes sans changer le pas de simulation : 8/8 summaries complets identiques hors `session_id`, et 4/4 comparaisons séquentiel/parallèle identiques.
- `scripts/check_kit.py` est absent : écart connu de `/close`, non bloquant pour les livrables applicatifs.
- `AGENTS.md` et `GEMINI.md` sont des résidus utilisateur hors périmètre, non inclus au commit.

## Dernière session (2026-09-10)

# Session du 2026-09-10

## Décisions prises
- Le contournement stateful v2 est invalidé comme candidat de gate : il évite le coût mais ne dépasse pas `aleatoire`.
- La suite est mise en pause pour rechercher d'autres alternatives ; v3 reste non mesuré.

## Livrables produits ou modifiés
- `scripts/danger_detour.gd` et raccord au décideur fixe : contournement avec cible/côté mémorisés, télémétrie et récupération de collision en attente de mesure.
- Campagnes `danger_zone_detour_v1` à `v3`, évaluateur corrigé, contrôles de reproductibilité et outils de diagnostic ajoutés.

## Hypothèses validées / invalidées
- VALIDE : le contournement est déterministe sur les scénarios automatisés ; exécution accélérée à pas 60 Hz identique aux traces archivées.
- INVALIDE : le candidat v2 produit un avantage reproductible contre `aleatoire` (5/12, seuil 9/12).
- EN ATTENTE : le changement de côté unique supprime-t-il les blocages constatés, ou une autre mécanique est-elle nécessaire ?

## Prochaine étape exacte
Comparer des alternatives de mécanique au danger, puis documenter une hypothèse et une campagne de calibration avant toute exécution. Ne pas ouvrir les seeds réservés ni modifier le learner.

## Question bloquante pour la session suivante
Quelle alternative au contournement stateful faut-il retenir pour l'axe danger ?
