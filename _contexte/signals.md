# Signals — ia_life (MAJ 2026-09-12)

## Actions ouvertes

- [P1|ouvert] Formaliser le contrat de la Phase 0 de l'apprentissage alimentaire.
  fait quand: observations, actions, reset, seeds, bras, critères et budget sont versionnés avant toute mesure.
  réf: `roadmap_apprentissage_fonctionnel_proposition.md` (Phase 0), `_docs/2026-09-10_recherche_apprentissage.md`.
- [P2|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P3|dormant] Axe danger v3 en pause pendant la Phase 0 de l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- L'analyse relève trois limites du chemin RL actuel : reset du monde incomplet, observation sans ressources alimentaires et récompense hors mort presque constante ; aucune correction n'est encore appliquée.
- La roadmap adoptée commence par une table persistante sur une micro-tâche alimentaire, avant une interface Gymnasium/PPO conditionnelle, puis les dangers et le LLM comme extensions mesurées.
- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- `IA_LIFE_HEADLESS_FIXED_FPS=60` accélère les campagnes sans changer le pas de simulation : 8/8 summaries complets identiques hors `session_id`, et 4/4 comparaisons séquentiel/parallèle identiques.
- `scripts/check_kit.py` est absent : écart connu de `/close`, non bloquant pour les livrables applicatifs.
- `AGENTS.md` et `GEMINI.md` sont des changements utilisateur hors périmètre, non inclus au commit.

## Dernière session (2026-09-12)

# Session du 2026-09-12

## Décisions prises
- Réorientation confirmée : la preuve alimentaire entre épisodes reste le chemin critique ; le danger demeure une extension conditionnelle.

## Livrables produits ou modifiés
- `_docs/decisions/2026-09-10_reorientation-apprentissage.md` : décision d'adoption enregistrée.
- `roadmap_apprentissage_fonctionnel_proposition.md` : statut Phase 0 et périmètre critique confirmés.
- `README.md`, `_contexte/` : état courant aligné avec la décision.

## Hypothèses validées / invalidées
- VALIDE : la Phase 0 est le préalable mesurable à toute implémentation d'apprentissage persistante.
- INVALIDE : la calibration du danger est un préalable au chemin alimentaire.
- EN ATTENTE : une table persistante apprend-elle une tâche alimentaire contrôlée avant tout recours à PPO ou à l'affinage d'un LLM ?

## Prochaine étape exacte
Exécuter la Phase 0 : versionner le contrat d'épisode, les seeds, les bras, les critères et le budget avant toute mesure.

## Question bloquante pour la session suivante
Aucune.
