# Signals — ia_life (MAJ 2026-09-10)

## Actions ouvertes

- [P1|ouvert] Décider d'adopter, d'amender ou d'écarter la réorientation de l'apprentissage proposée.
  fait quand: une décision documentée fixe le chemin critique et la première phase réellement engagée.
  réf: `_docs/2026-09-10_recherche_apprentissage.md`, `roadmap_apprentissage_fonctionnel_proposition.md`.
- [P2|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P3|dormant] Axe apprentissage v2 suspendu tant qu'une réorientation n'est pas adoptée ou que l'ancien gate v3 n'est pas passé.
  fait quand: une roadmap adoptée ouvre une phase d'apprentissage, ou les Phases 0-5 v3 sont [FAIT] et le gate réservé Phase 4 passe.
  réf: `roadmap_apprentissage_v2.md`, `roadmap_apprentissage_fonctionnel_proposition.md`, `roadmap_environnement_apprenable_v3.md`.

## Contexte chaud

- L'analyse relève trois limites du chemin RL actuel : reset du monde incomplet, observation sans ressources alimentaires et récompense hors mort presque constante ; aucune correction n'est encore appliquée.
- La proposition commence par une table persistante sur une micro-tâche alimentaire, avant une interface Gymnasium/PPO conditionnelle, puis les dangers et le LLM comme extensions mesurées.
- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- `IA_LIFE_HEADLESS_FIXED_FPS=60` accélère les campagnes sans changer le pas de simulation : 8/8 summaries complets identiques hors `session_id`, et 4/4 comparaisons séquentiel/parallèle identiques.
- `scripts/check_kit.py` est absent : écart connu de `/close`, non bloquant pour les livrables applicatifs.
- `AGENTS.md` et `GEMINI.md` sont des changements utilisateur hors périmètre, non inclus au commit.

## Dernière session (2026-09-10)

# Session du 2026-09-10

## Décisions prises
- Proposition non adoptée : sortir le danger du chemin critique de la première preuve d'apprentissage alimentaire.

## Livrables produits ou modifiés
- `_docs/2026-09-10_recherche_apprentissage.md` : analyse du code et recherches Web/GitHub sourcées.
- `roadmap_apprentissage_fonctionnel_proposition.md` : roadmap de recherche, implémentation et validation.
- `roadmap_apprentissage_v2.md`, `roadmap_environnement_apprenable_v3.md` : renvois vers la proposition, sans changement de statut.

## Hypothèses validées / invalidées
- VALIDE : le chemin RL existant n'est qu'un socle de transport ; son reset, observation et retour ne suffisent pas encore à entraîner une politique alimentaire.
- INVALIDE : l'échec des politiques fixes de danger suffit à conclure que le système global est inapprenable.
- EN ATTENTE : une table persistante apprend-elle une tâche alimentaire contrôlée avant tout recours à PPO ou à l'affinage d'un LLM ?

## Prochaine étape exacte
Décider du statut de la roadmap proposée, puis, si elle est adoptée, engager sa Phase 0 : contrat d'épisode, seeds, bras, critères et budget préenregistrés.

## Question bloquante pour la session suivante
La roadmap d'apprentissage proposée est-elle adoptée comme nouveau chemin critique ?
