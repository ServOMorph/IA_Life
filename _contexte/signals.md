# Signals — ia_life (MAJ 2026-09-27)

## Actions ouvertes

- [P1|ouvert] Isoler la cause des échecs de navigation T1 v4 après le premier choix, puis geler un nouveau contrat et de nouvelles réserves avant toute campagne.
  fait quand: une hypothèse causale est testée sur diagnostic hors validation et le contrat suivant est versionné avant mesure comparative.
  réf: `_docs/decisions/2026-09-27_t1-v4-gate-non-atteint.md`, `experiments/apprentissage_t1_contrat_v4.md`, `roadmap_apprentissage_fonctionnel_proposition.md` (Phase 4).
- [P2|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; écart connu à corriger en Phase 4.
- [P3|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P4|dormant] Axe danger v3 en pause pendant l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- T0 v4 franchit le gate sur 1 248 résultats ; Phase 3 franchit son gate technique via le bridge TCP/JSONL et les adaptateurs Gymnasium T0/monde.
- T1 v4 : `trained` 96/96 premiers choix corrects, 70/96 consommations ; gate non atteint. Les trois checkpoints sont à 1 000 et leur replay est stable après recharge. Les tests finaux T0/T1 restent fermés ; T2/T3 non engagés.
- Les modifications ROBERTO/com_telephone, `AGENTS.md`, `GEMINI.md`, `.claude/CLAUDE.md` et `.claude/commands/roberto.md` présentes dans le working tree ne font pas partie de cette clôture.
- `scripts/check_kit.py` est absent : écart connu à corriger en Phase 4 ; le contrôle demandé par `/close` ne peut pas être exécuté.

## Dernière session (2026-09-27)

# Session du 2026-09-27

## Décisions prises
- T0 v4 et la Phase 3 franchissent leurs gates respectifs ; la Phase 4 reste ouverte, T1 v4 échouant au seuil de consommation.

## Livrables produits ou modifiés
- Contrats, code, campagnes et résultats T0 v4 et T1 v2–v4 : produits et évalués.
- Bridge TCP/JSONL, adaptateurs Gymnasium et tests Phase 3 : produits et exécutés.
- Roadmap, décisions, contexte, README et CHANGELOG : actualisés par `/close`.

## Hypothèses validées / invalidées
- VALIDE : T0 v4 apprend et conserve la politique des huit secteurs ; T1 v4 apprend le premier choix.
- INVALIDE : ce premier choix suffit au gate T1 ; pivot vers le diagnostic de navigation après le premier pas.
- EN ATTENTE : cause précise des échecs de navigation T1 v4.

## Prochaine étape exacte
Isoler les échecs de navigation T1 v4 hors validation, puis versionner une hypothèse et des réserves neuves avant toute nouvelle campagne.

## Question bloquante pour la session suivante
Aucune.
